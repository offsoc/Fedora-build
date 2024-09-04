#!/bin/bash

# 脚本生成器示例
# 用于自动创建新的 Bash 脚本文件

# 默认值
AUTHOR_NAME="APT27"
COMPANY_NAME="offsec"
CONTACT_EMAIL="APT27@offsec.com"
SCRIPT_TYPE="Script"
VERSION="1.0"
LICENSE="MIT"

# 获取当前日期和时间
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%H:%M:%S")

# 获取当前脚本名称
SCRIPT_NAME=$(basename "$0")

# 创建脚本文件
create_script() {
    local script_name=$1
    local script_type=$2
    local author_name=$3
    local company_name=$4
    local contact_email=$5
    local version=$6
    local license=$7

    # 编写脚本内容
    cat <<EOF > "$script_name"
#!/bin/bash
#
# =============================================================================
# Script Name: $script_name
# Description: [Description of the script]
# Author: $author_name
# Company: $company_name
# Contact: $contact_email
# Created: $CURRENT_DATE $CURRENT_TIME
# Type: $script_type
# Version: $version
# License: $license
# =============================================================================
#
# This script performs the following tasks:
# [Describe the tasks the script will perform]
#
# Usage:
#   ./$script_name [options]
#
# Options:
#   -h, --help  Show this help message and exit.
#
# =============================================================================

# Your script logic starts here
EOF

    echo "Script $script_name created successfully."
}

# 检查参数
if [ $# -lt 1 ]; then
    echo "Usage: $0 <script_name> [script_type] [author_name] [company_name] [contact_email] [version] [license]"
    exit 1
fi

# 读取参数
SCRIPT_NAME=$1
SCRIPT_TYPE=${2:-$SCRIPT_TYPE}
AUTHOR_NAME=${3:-$AUTHOR_NAME}
COMPANY_NAME=${4:-$COMPANY_NAME}
CONTACT_EMAIL=${5:-$CONTACT_EMAIL}
VERSION=${6:-$VERSION}
LICENSE=${7:-$LICENSE}

# 创建脚本
create_script "$SCRIPT_NAME" "$SCRIPT_TYPE" "$AUTHOR_NAME" "$COMPANY_NAME" "$CONTACT_EMAIL" "$VERSION" "$LICENSE"
