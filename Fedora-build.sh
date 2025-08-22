#!/bin/bash
#
# =============================================================================
# Script Name: build-fedora-image.sh
# Description: Ultimate Fedora image builder with full automation and Cloud conversion
# Author: offsec
# =============================================================================

LOG_FILE=~/fedora_image_build.log
BUILD_THREADS=$(nproc)
RESULT_DIR="/var/lmc"
ISO_OUTPUT_DIR="$PWD/output"
RELEASE_VERSION="44"
IMAGE_TYPES=()  # Supports multiple types
DESKTOP_ENVIRONMENT="Workstation"
ISO_NAME=""
VOL_ID=""
PROJECT_NAME=""
KS_FILE=""
CLOUD_FORMATS=("raw" "qcow2" "vhd" "virtualbox" "ova")
RETRY_COUNT=2

# ================================
# Display help
# ================================
function show_help() {
cat <<EOF
Usage: $0 [options]

Options:
  -t, --type <image-types>       Image types, supports multiple types separated by space: live cloud server coreos netinstall
  -o, --output-dir <dir>         ISO output directory (default: ./output)
  -r, --release <version>        Fedora release version (default: 44)
  -d, --desktop <environment>    Desktop environment (default: Workstation)
  --ks-file <file>               Kickstart file path (required)
  --cloud-formats <list>         Cloud image formats, separated by space (default: raw qcow2 vhd virtualbox ova)
  --project-name <name>          Project name (auto-generated)
  --vol-id <id>                  Volume ID (auto-generated)
  -h, --help                     Show this help message
EOF
}

# ================================
# Check root privileges
# ================================
function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as root." | tee -a "$LOG_FILE"
        exit 1
    fi
}

# ================================
# Check required tools
# ================================
function check_tools() {
    for tool in livemedia-creator df mkdir tee qemu-img VBoxManage; do
        if ! command -v $tool &> /dev/null; then
            echo "Error: $tool not found. Please install it first." | tee -a "$LOG_FILE"
            exit 1
        fi
    done
}

# ================================
# Parse command line arguments
# ================================
function parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -t|--type) shift; IMAGE_TYPES=($@); break ;;
            -o|--output-dir) ISO_OUTPUT_DIR="$2"; shift ;;
            -r|--release) RELEASE_VERSION="$2"; shift ;;
            -d|--desktop) DESKTOP_ENVIRONMENT="$2"; shift ;;
            --ks-file) KS_FILE="$2"; shift ;;
            --vol-id) VOL_ID="$2"; shift ;;
            --project-name) PROJECT_NAME="$2"; shift ;;
            --cloud-formats) shift; CLOUD_FORMATS=($@); break ;;
            -h|--help) show_help; exit 0 ;;
            *) echo "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done

    if [ -z "$KS_FILE" ]; then
        echo "Error: Kickstart file must be specified (--ks-file)" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# ================================
# Prepare output directories
# ================================
function prepare_output_dir() {
    mkdir -p "$ISO_OUTPUT_DIR" "$RESULT_DIR"
}

# ================================
# Generate ISO names, volume IDs, and project names
# ================================
function generate_names() {
    for type in "${IMAGE_TYPES[@]}"; do
        local default_name="Fedora-${DESKTOP_ENVIRONMENT}-${RELEASE_VERSION}-${type}.iso"
        ISO_NAMES["$type"]=${ISO_NAME:-$default_name}
        VOL_IDS["$type"]=${VOL_ID:-"Fedora-${DESKTOP_ENVIRONMENT}-${RELEASE_VERSION}-${type}"}
        PROJECT_NAMES["$type"]=${PROJECT_NAME:-"Fedora-${DESKTOP_ENVIRONMENT}-${RELEASE_VERSION}-${type}"}
    done
}

# ================================
# Detect image type from kickstart
# ================================
function detect_image_type() {
    local ks="$1"
    if grep -iqE 'livecd|workstation' "$ks"; then echo "live"
    elif grep -iqE 'server' "$ks"; then echo "server"
    elif grep -iqE 'cloud' "$ks"; then echo "cloud"
    elif grep -iqE 'iot|coreos' "$ks"; then echo "coreos"
    else echo "standard"; fi
}

# ================================
# Build ISO image
# ================================
function build_image() {
    local type="$1"
    local retry=0
    while [ $retry -le $RETRY_COUNT ]; do
        echo "Building $type image, attempt #$((retry+1))..." | tee -a "$LOG_FILE"
        if livemedia-creator \
            --ks "$KS_FILE" \
            --make-iso \
            --no-virt \
            --resultdir "$RESULT_DIR" \
            --project "${PROJECT_NAMES[$type]}" \
            --volid "${VOL_IDS[$type]}" \
            --iso-only \
            --iso-name "$ISO_OUTPUT_DIR/${ISO_NAMES[$type]}" \
            --releasever "$RELEASE_VERSION" \
            --macboot | tee -a "$LOG_FILE"; then
            echo "$type build succeeded: $ISO_OUTPUT_DIR/${ISO_NAMES[$type]}" | tee -a "$LOG_FILE"
            break
        else
            echo "$type build failed, retrying..." | tee -a "$LOG_FILE"
            retry=$((retry+1))
        fi
    done
    if [ $retry -gt $RETRY_COUNT ]; then
        echo "$type build failed, reached max retries $RETRY_COUNT" | tee -a "$LOG_FILE"
        return 1
    fi
}

# ================================
# Convert Cloud images to different formats
# ================================
function convert_cloud_image() {
    local iso_path="$ISO_OUTPUT_DIR/${ISO_NAMES["cloud"]}"
    [[ ! -f "$iso_path" ]] && return
    echo "Starting Cloud image conversion..." | tee -a "$LOG_FILE"
    for format in "${CLOUD_FORMATS[@]}"; do
        {
            case $format in
                raw) cp "$iso_path" "${iso_path%.iso}.raw" ;;
                qcow2) qemu-img convert -f raw -O qcow2 "$iso_path" "${iso_path%.iso}.qcow2" ;;
                vhd) qemu-img convert -f raw -O vpc "$iso_path" "${iso_path%.iso}.vhd" ;;
                virtualbox) VBoxManage convertfromraw "$iso_path" "${iso_path%.iso}.vdi" --format VDI ;;
                ova)
                    VBoxManage convertfromraw "$iso_path" "${iso_path%.iso}.vdi" --format VDI
                    VBoxManage import "${iso_path%.iso}.ovf" --vsys 0 --cpus 2 --memory 2048 --network adapter1=nat
                    ;;
                *) echo "Unknown Cloud image format: $format" ;;
            esac
        } &
    done
    wait
    echo "Cloud image conversion finished." | tee -a "$LOG_FILE"
}

# ================================
# Main execution
# ================================
check_root
parse_args "$@"
check_tools
prepare_output_dir

# Detect image type if none specified
if [ ${#IMAGE_TYPES[@]} -eq 0 ]; then
    IMAGE_TYPES=($(detect_image_type "$KS_FILE"))
fi

declare -A ISO_NAMES
declare -A VOL_IDS
declare -A PROJECT_NAMES
generate_names

# Build all image types concurrently
for type in "${IMAGE_TYPES[@]}"; do
    build_image "$type" &
done
wait

# Convert Cloud images
[[ " ${IMAGE_TYPES[@]} " =~ " cloud " ]] && convert_cloud_image

echo "All builds completed. Output directory: $ISO_OUTPUT_DIR" | tee -a "$LOG_FILE"
