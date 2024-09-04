#!/bin/bash
#
# =============================================================================
# Script Name: build-fedora-image.sh
# Description: A script to build and customize Fedora installation images.
# Author: offsec
# Company: offsec.com
# Contact: offapt@gmail.com
# Created: 20240904
# Version: v1.0
# License: GPL
# =============================================================================
#
# This script automates the process of building and customizing Fedora images.
# It supports creating Live, Standard, Netinstall, Cloud, CoreOS, and Server images.
#
# Usage:
#   ./build-fedora-image.sh [options]
#
# Options:
#   -t, --type <image-type>       Specify the type of image to build (live, standard, netinstall, cloud, coreos, server).
#   -d, --desktop <environment>   Specify the desktop environment (GNOME, KDE, XFCE) for live and netinstall types.
#   -r, --release <version>       Specify the Fedora release version (default is 40).
#   -p, --repo-path <dir>         Specify the local repository path for netinstall images.
#   -f, --cloud-format <format>   Specify the format for cloud images (raw, vhd, qcow2, virtualbox, ova).
#   -v, --system-version <version> Specify the system version (standard, lot, cloud, coreos, server).
#   -o, --output-dir <dir>        Specify the output directory for the built images.
#   -l, --log-file <file>         Specify the log file path.
#   -h, --help                    Show this help message and exit.
#
# =============================================================================

# Your script logic starts here
# 默认参数
ISO_OUTPUT_DIR=~/custom-fedora-images        # 默认输出目录
RELEASE_VERSION=40                           # 默认 Fedora 版本
KS_FILE=~/custom-fedora.ks                   # 默认 Kickstart 文件路径
REPO_PATH=""                                 # 本地仓库路径（可选）
VOL_ID="Custom_Fedora"                       # ISO 卷标
PROJECT_NAME="Custom Fedora OS"              # 项目名称
LOG_FILE=~/fedora_image_build.log            # 日志文件
DESKTOP_ENVIRONMENTS=("GNOME")               # 默认桌面环境列表
IMAGE_TYPE="live"                            # 镜像类型 (live, standard, netinstall, iot, cloud, coreos, server)
CLOUD_FORMAT="raw"                           # 默认 Cloud 镜像格式
CLOUD_FORMATS=("raw" "vhd" "qcow2" "virtualbox" "ova")  # 默认支持的 Cloud 格式
SYSTEM_TYPE="standard"                       # 系统定制类型 (standard, lot, cloud, coreos, server)
SYSTEM_VERSIONS=("standard" "lot" "cloud" "coreos" "server")  # 支持的系统版本
BUILD_THREADS=4                              # 默认构建线程数

# 监控磁盘和网络使用
function monitor_system() {
    echo "监控系统资源..." | tee -a "$LOG_FILE"
    
    echo "磁盘使用情况:" | tee -a "$LOG_FILE"
    df -h | tee -a "$LOG_FILE"
    
    echo "网络带宽使用情况:" | tee -a "$LOG_FILE"
    if command -v ifstat &> /dev/null; then
        ifstat -i eth0 1 10 | tee -a "$LOG_FILE"
    else
        echo "未找到 ifstat，无法监控网络带宽使用情况。" | tee -a "$LOG_FILE"
    fi
}

# 显示帮助信息
function show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -t, --type <image-type>        指定镜像类型 (live, standard, netinstall, iot, cloud, coreos, server)"
    echo "  -o, --output-dir <dir>         指定ISO输出目录 (默认: $ISO_OUTPUT_DIR)"
    echo "  -n, --iso-name <name>          指定输出ISO文件名 (默认: 按桌面环境和系统版本生成)"
    echo "  -r, --release <version>        指定Fedora版本 (默认: $RELEASE_VERSION)"
    echo "  -p, --repo-path <dir>          指定本地仓库路径 (默认: 不使用)"
    echo "  -d, --desktop <environment>    指定桌面环境 (GNOME, KDE, XFCE) (仅网络安装镜像使用)"
    echo "  -f, --cloud-format <format>    指定云镜像格式 (raw, vhd, qcow2, virtualbox, ova) (仅云镜像使用)"
    echo "  -s, --system-type <type>       指定系统定制类型 (standard, lot, cloud, coreos, server)"
    echo "  -v, --system-version <version> 指定系统版本 (standard, lot, cloud, coreos, server)"
    echo "  -l, --log-file <file>          指定日志文件路径 (默认: $LOG_FILE)"
    echo "  -h, --help                     显示帮助信息"
}

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--type) IMAGE_TYPE="$2"; shift ;;
        -o|--output-dir) ISO_OUTPUT_DIR="$2"; shift ;;
        -n|--iso-name) ISO_NAME="$2"; shift ;;
        -r|--release) RELEASE_VERSION="$2"; shift ;;
        -p|--repo-path) REPO_PATH="$2"; shift ;;
        -d|--desktop) DESKTOP_ENVIRONMENTS=("$2"); shift ;;
        -f|--cloud-format) CLOUD_FORMAT="$2"; shift ;;
        -s|--system-type) SYSTEM_TYPE="$2"; shift ;;
        -v|--system-version) SYSTEM_VERSION="$2"; shift ;;
        -l|--log-file) LOG_FILE="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "未知选项: $1"; show_help; exit 1 ;;
    esac
    shift
done

# 设置默认系统版本，如果用户未指定
SYSTEM_VERSION=${SYSTEM_VERSION:-$RELEASE_VERSION}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用root权限运行此脚本." | tee -a "$LOG_FILE"
  exit 1
fi

# 检查必要工具是否安装
function check_tools() {
    local tools=("dnf" "livemedia-creator" "reposync" "qemu-img" "VBoxManage" "df" "ifstat")
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            echo "错误: 未找到工具 $tool，请先安装它。" | tee -a "$LOG_FILE"
            exit 1
        fi
    done
}

check_tools

# 检查输出目录
if [ ! -d "$ISO_OUTPUT_DIR" ]; then
    echo "创建输出目录 $ISO_OUTPUT_DIR" | tee -a "$LOG_FILE"
    mkdir -p "$ISO_OUTPUT_DIR"
fi

# 生成ISO文件名
function generate_iso_name() {
    local desktop_env="$1"
    local version="$2"
    echo "${desktop_env}_${version}_Fedora_${RELEASE_VERSION}.iso"
}

# 为指定的镜像格式生成 Cloud 镜像
function convert_cloud_image() {
    local image_path="$1"
    for format in "${CLOUD_FORMATS[@]}"; do
        case $format in
            raw)
                cp "$image_path" "${image_path%.iso}.raw" | tee -a "$LOG_FILE" &
                ;;
            vhd)
                qemu-img convert -f raw -O vpc "$image_path" "${image_path%.iso}.vhd" | tee -a "$LOG_FILE" &
                ;;
            qcow2)
                qemu-img convert -f raw -O qcow2 "$image_path" "${image_path%.iso}.qcow2" | tee -a "$LOG_FILE" &
                ;;
            virtualbox)
                VBoxManage convertfromraw "$image_path" "${image_path%.iso}.vdi" --format VDI | tee -a "$LOG_FILE" &
                ;;
            ova)
                VBoxManage convertfromraw "$image_path" "${image_path%.iso}.vdi" --format VDI | tee -a "$LOG_FILE" &
                VBoxManage import "${image_path%.iso}.ovf" --vsys 0 --cpus 2 --memory 2048 --network adapter1=nat | tee -a "$LOG_FILE" &
                ;;
            *)
                echo "未知的云镜像格式: $format" | tee -a "$LOG_FILE"
                ;;
        esac
    done
    wait  # 等待所有后台任务完成
}

# 针对不同镜像类型的处理逻辑
function build_image() {
    local iso_name
    case $IMAGE_TYPE in
        live)
            iso_name=$(generate_iso_name "${DESKTOP_ENVIRONMENTS[0]}" "$SYSTEM_VERSION")
            echo "构建 Live 镜像..." | tee -a "$LOG_FILE"
            echo "%packages" >> "$KS_FILE"
            echo "@^gnome-desktop-environment" >> "$KS_FILE"
            echo "%end" >> "$KS_FILE"
            echo "构建 Fedora Live 镜像..." | tee -a "$LOG_FILE"
            livemedia-creator --ks "$KS_FILE" \
                --no-virt \
                --make-iso \
                --project "$PROJECT_NAME" \
                --releasever "$RELEASE_VERSION" \
                --volid "$VOL_ID" \
                --iso-only \
                --iso-name "$ISO_OUTPUT_DIR/$iso_name" | tee -a "$LOG_FILE"
            ;;
        standard)
            iso_name=$(generate_iso_name "Standard" "$SYSTEM_VERSION")
            echo "构建标准安装镜像..." | tee -a "$LOG_FILE"
            livemedia-creator --ks "$KS_FILE" \
                --make-disk \
                --project "$PROJECT_NAME" \
                --releasever "$RELEASE_VERSION" \
                --volid "$VOL_ID" \
                --iso-only \
                --iso-name "$ISO_OUTPUT_DIR/$iso_name" | tee -a "$LOG_FILE"
            ;;
        netinstall)
            iso_name=$(generate_iso_name "Netinstall" "$SYSTEM_VERSION")
            echo "构建网络安装镜像..." | tee -a "$LOG_FILE"
            cp /usr/share/spin-kickstarts/fedora-netinstall.ks "$KS_FILE"
            livemedia-creator --ks "$KS_FILE" \
                --make-iso \
                --no-virt \
                --project "$PROJECT_NAME Netinstall" \
                --releasever "$RELEASE_VERSION" \
                --volid "$VOL_ID" \
                --iso-only \
                --iso-name "$ISO_OUTPUT_DIR/$iso_name" | tee -a "$LOG_FILE"
            ;;
        iot)
            iso_name=$(generate_iso_name "IoT" "$SYSTEM_VERSION")
            echo "构建 IoT 镜像..." | tee -a "$LOG_FILE"
            cp /usr/share/spin-kickstarts/fedora-iot.ks "$KS_FILE"
            livemedia-creator --ks "$KS_FILE" \
                --make-iso \
                --no-virt \
                --project "$PROJECT_NAME IoT" \
                --releasever "$RELEASE_VERSION" \
                --volid "$VOL_ID" \
                --iso-only \
                --iso-name "$ISO_OUTPUT_DIR/$iso_name" | tee -a "$LOG_FILE"
            ;;
        cloud)
            iso_name=$(generate_iso_name "Cloud" "$SYSTEM_VERSION")
            echo "构建 Cloud 镜像..." | tee -a "$LOG_FILE"
            cp /usr/share/spin-kickstarts/fedora-cloud.ks "$KS_FILE"
            livemedia-creator --ks "$KS_FILE" \
                --make-iso \
                --no-virt \
                --project "$PROJECT_NAME Cloud" \
                --releasever "$RELEASE_VERSION" \
                --volid "$VOL_ID" \
                --iso-only \
                --iso-name "$ISO_OUTPUT_DIR/$iso_name" | tee -a "$LOG_FILE"

            echo "转换 Cloud 镜像为不同格式..." | tee -a "$LOG_FILE"
            convert_cloud_image "$ISO_OUTPUT_DIR/$iso_name"
            ;;
        coreos)
            iso_name=$(generate_iso_name "CoreOS" "$SYSTEM_VERSION")
            echo "构建 CoreOS 版本镜像..." | tee -a "$LOG_FILE"
            cp /usr/share/spin-kickstarts/fedora-coreos.ks "$KS_FILE"
            livemedia-creator --ks "$KS_FILE" \
                --make-iso \
                --no-virt \
                --project "$PROJECT_NAME CoreOS" \
                --releasever "$RELEASE_VERSION" \
                --volid "$VOL_ID" \
                --iso-only \
                --iso-name "$ISO_OUTPUT_DIR/$iso_name" | tee -a "$LOG_FILE"
            ;;
        server)
            iso_name=$(generate_iso_name "Server" "$SYSTEM_VERSION")
            echo "构建 Server 镜像..." | tee -a "$LOG_FILE"
            cp /usr/share/spin-kickstarts/fedora-server.ks "$KS_FILE"
            livemedia-creator --ks "$KS_FILE" \
                --make-iso \
                --no-virt \
                --project "$PROJECT_NAME Server" \
                --releasever "$RELEASE_VERSION" \
                --volid "$VOL_ID" \
                --iso-only \
                --iso-name "$ISO_OUTPUT_DIR/$iso_name" | tee -a "$LOG_FILE"
            ;;
        *)
            echo "错误: 不支持的镜像类型 $IMAGE_TYPE" | tee -a "$LOG_FILE"
            exit 1
            ;;
    esac
}

# 主执行部分
monitor_system
build_image

echo "构建过程完成。" | tee -a "$LOG_FILE"
echo "输出目录: $ISO_OUTPUT_DIR" | tee -a "$LOG_FILE"
