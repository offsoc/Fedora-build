#!/bin/bash
#
# =============================================================================
# Script Name: fedora-build.sh
# Description: Enterprise-grade Fedora Official Image Builder
# Author: offsec
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ================================
# Default configs
# ================================
OUTPUT_DIR="$PWD/output"
TMP_DIR_BASE=$(mktemp -d /var/tmp/fedora-build-tmp.XXXX)
RELEASE_VERSION=""
DESKTOP_ENVIRONMENT="Workstation"
IMAGE_TYPES=()
KS_FILE=""
FORCE=0
JOBS=$(nproc)
BACKGROUND_BUILDS=1
CLOUD_FORMATS=("raw" "qcow2" "vhd" "vdi" "ova")

FEDORA_VERSIONS=("38" "39" "40" "41" "42" "43" "44" "45" "46" "47")
DESKTOPS=("Workstation" "KDE" "XFCE" "LXQt" "LXDE" "MATE" "Cinnamon" "i3")

# ================================
# Helper functions
# ================================
function cleanup() {
    echo "Cleaning up temporary directory: $TMP_DIR_BASE"
    rm -rf "$TMP_DIR_BASE"
}
trap cleanup EXIT

function show_help() {
cat <<EOF
Usage: $0 [options]
Options:
  -k, --ks-file <file>         Kickstart file (required)
  -t, --type <types>           Image types: live server cloud disk
  -v, --version <version>      Fedora version (default: latest)
  -d, --desktop <environment>  Desktop environment (default: Workstation)
  -o, --output-dir <dir>       Output directory (default: ./output)
  -j, --jobs <num>             Parallel builds (default: all cores)
  -f, --force                  Force overwrite existing results_dir
  --cloud-formats <list>       Cloud formats: raw qcow2 vhd vdi ova
  --no-background              Run builds serially in the foreground (disable parallelism)
  -h, --help                   Show this help
EOF
}

function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Please run as root"
        exit 1
    fi
}

function install_tools_if_missing() {
    local missing=()
    for tool in livemedia-creator qemu-img; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Installing missing tools: ${missing[*]}"
        dnf install -y "${missing[@]}"
    fi

    local need_vbox=0
    for fmt in "${CLOUD_FORMATS[@]}"; do
        if [[ "$fmt" =~ ^(vdi|ova)$ ]]; then
            need_vbox=1
            break
        fi
    done
    if [[ $need_vbox -eq 1 && ! $(command -v VBoxManage) ]]; then
        echo "Warning: VBoxManage not found. To build OVA/VDI, please install VirtualBox manually."
    fi
}

function validate_release() {
    [[ -z "$RELEASE_VERSION" ]] && RELEASE_VERSION="${FEDORA_VERSORS[-1]}"
    for v in "${FEDORA_VERSIONS[@]}"; do
        [[ "$RELEASE_VERSION" == "$v" ]] && return
    done
    echo "Unsupported Fedora version: $RELEASE_VERSION"
    exit 1
}

function validate_desktop() {
    for d in "${DESKTOPS[@]}"; do
        [[ "$DESKTOP_ENVIRONMENT" == "$d" ]] && return
    done
    echo "Unsupported Desktop: $DESKTOP_ENVIRONMENT"
    exit 1
}

function parse_args() {
    local types_found=0
    while [[ $# -gt 0 ]]; do
        case $1 in
            -k|--ks-file)
                KS_FILE="$2"
                shift 2
                ;;
            -t|--type)
                types_found=1
                shift
                IMAGE_TYPES=()
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    IMAGE_TYPES+=("$1")
                    shift
                done
                ;;
            -v|--version)
                RELEASE_VERSION="$2"
                shift 2
                ;;
            -d|--desktop)
                DESKTOP_ENVIRONMENT="$2"
                shift 2
                ;;
            -o|--output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -j|--jobs)
                JOBS="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=1
                shift
                ;;
            --cloud-formats)
                shift
                CLOUD_FORMATS=()
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    CLOUD_FORMATS+=("$1")
                    shift
                done
                ;;
            --no-background)
                BACKGROUND_BUILDS=0
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option $1"
                show_help
                exit 1
                ;;
        esac
    done

    [[ -z "$KS_FILE" ]] && { echo "Kickstart file is required"; exit 1; }
    [[ ! -f "$KS_FILE" ]] && { echo "Kickstart file not found: $KS_FILE"; exit 1; }
    validate_release
    validate_desktop
    [[ $types_found -eq 0 ]] && IMAGE_TYPES=($(detect_image_type "$KS_FILE"))
}

function prepare_result_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        if [[ $FORCE -eq 1 ]]; then
            echo "Forcing overwrite of $dir"
            rm -rf "$dir"
        else
            local backup_dir="${dir}_backup_$(date +%F_%H%M%S)"
            echo "Existing directory found. Backing up to $backup_dir"
            mv "$dir" "$backup_dir"
        fi
    fi
    mkdir -p "$dir"
}

function detect_image_type() {
    local ks="$1"
    if grep -iqE 'livecd|workstation' "$ks"; then echo "live"
    elif grep -iqE 'server' "$ks"; then echo "server"
    elif grep -iqE 'cloud' "$ks"; then echo "cloud"
    elif grep -iqE 'iot|coreos|disk' "$ks"; then echo "disk"
    else echo "standard"
    fi
}

function verify_iso_signature() {
    local iso_file="$1"
    local gpg_key="/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$(basename "$RELEASE_VERSION")-$(uname -m)"

    [[ ! -f "$iso_file" ]] && { echo "ISO file not found, skipping verification"; return; }

    echo "Verifying ISO signature for $iso_file..."
    if [[ ! -f "$gpg_key" ]]; then
        echo "Fedora GPG key not found locally. Attempting to download..."
        curl -fsSL "https://fedoraproject.org/fedora.gpg" -o "$HOME/fedora.gpg"
        gpg --import "$HOME/fedora.gpg"
        gpg_key="$HOME/fedora.gpg"
    fi

    local sig_file="${iso_file}.sig"
    [[ ! -f "$sig_file" ]] && { echo "Signature file not found, skipping verification"; return; }

    gpg --verify "$sig_file" "$iso_file" || { echo "ISO signature verification failed!"; exit 1; }
    echo "ISO signature verified successfully"
}

function build_image_job() {
    local type="$1"
    local base_name=$(basename "$KS_FILE" .ks)
    local result_dir="$OUTPUT_DIR/${type}-${DESKTOP_ENVIRONMENT}-${RELEASE_VERSION}-${base_name}-result"
    
    echo "Starting build for: $type/ $DESKTOP_ENVIRONMENT Fedora-$RELEASE_VERSION"
    echo "Log file: $OUTPUT_DIR/${type}-${base_name}.log"
    echo "--------------------------------------------------"

    local tmp_dir=$(mktemp -d --tmpdir="$TMP_DIR_BASE" "${type}-tmp-XXXX")
    prepare_result_dir "$result_dir"

    local make_arg
    case "$type" in
        live) make_arg="--make-iso" ;;
        server|cloud|disk) make_arg="--make-disk --image-type=qcow2" ;;
        *) echo "Unknown image type: $type"; return ;;
    esac

    /usr/bin/time -v livemedia-creator \
        $make_arg \
        --ks "$KS_FILE" \
        --no-virt \
        --releasever "$RELEASE_VERSION" \
        --resultdir "$result_dir" \
        --tmp "$tmp_dir" 2>&1 | tee "$OUTPUT_DIR/${type}-${base_name}.log"

    echo "--------------------------------------------------"
    echo "Build for $type finished."

    [[ "$type" == "live" ]] && verify_iso_signature "$(ls "$result_dir"/LiveOS/*.iso 2>/dev/null | head -n1)"
}

function convert_cloud_images() {
    echo "Starting cloud image conversions..."
    for type in "${IMAGE_TYPES[@]}"; do
        [[ "$type" != "cloud" ]] && continue
        local qcow2_path="$OUTPUT_DIR/cloud-${DESKTOP_ENVIRONMENT}-${RELEASE_VERSION}-$(basename "$KS_FILE" .ks)-result/images/disk.qcow2"
        [[ ! -f "$qcow2_path" ]] && continue
        
        echo "Converting cloud image to requested formats: ${CLOUD_FORMATS[*]}..."
        for fmt in "${CLOUD_FORMATS[@]}"; do
            local output_file="$OUTPUT_DIR/disk.${fmt}"
            case $fmt in
                raw) qemu-img convert -f qcow2 -O raw "$qcow2_path" "$output_file" ;;
                qcow2) cp "$qcow2_path" "$output_file" ;;
                vhd) qemu-img convert -f qcow2 -O vpc "$qcow2_path" "$output_file" ;;
                vdi)
                    if command -v VBoxManage &>/dev/null; then
                        qemu-img convert -f qcow2 -O raw "$qcow2_path" "$OUTPUT_DIR/disk.raw"
                        VBoxManage convertfromraw "$OUTPUT_DIR/disk.raw" "$output_file" --format VDI
                    else
                        echo "Skipping VDI conversion, VBoxManage not found."
                    fi
                    ;;
                ova)
                    if command -v VBoxManage &>/dev/null; then
                        local vdi_file="$OUTPUT_DIR/disk.vdi"
                        if [[ ! -f "$vdi_file" ]]; then
                            qemu-img convert -f qcow2 -O raw "$qcow2_path" "$OUTPUT_DIR/disk.raw"
                            VBoxManage convertfromraw "$OUTPUT_DIR/disk.raw" "$vdi_file" --format VDI
                        fi
                        VBoxManage export "$vdi_file" -o "$output_file" --ovf10
                    else
                        echo "Skipping OVA conversion, VBoxManage not found."
                    fi
                    ;;
                *)
                    echo "Unsupported cloud format: $fmt. Skipping."
                    ;;
            esac
        done
        [[ -f "$OUTPUT_DIR/disk.raw" ]] && rm "$OUTPUT_DIR/disk.raw"
    done
}

# ================================
# Main Execution
# ================================
check_root
parse_args "$@"
install_tools_if_missing

mkdir -p "$OUTPUT_DIR"

echo "Starting builds for: ${IMAGE_TYPES[*]}"
echo "Fedora Version: $RELEASE_VERSION"
echo "Desktop: $DESKTOP_ENVIRONMENT"
echo "Output Directory: $OUTPUT_DIR"
echo "Kickstart File: $KS_FILE"
echo "--------------------------------------------------"

if [[ $BACKGROUND_BUILDS -eq 1 ]]; then
    # Run builds in parallel
    declare -a PIDS=()
    for type in "${IMAGE_TYPES[@]}"; do
        build_image_job "$type" &
        PIDS+=($!)
        while [[ $(jobs -r | wc -l) -ge $JOBS ]]; do sleep 1; done
    done
    wait
else
    # Run builds serially in the foreground
    for type in "${IMAGE_TYPES[@]}"; do
        build_image_job "$type"
    done
fi

echo "All builds finished."
convert_cloud_images
echo "Final output is in: $OUTPUT_DIR"
