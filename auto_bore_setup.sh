#!/bin/bash

# ==============================================================================
# 自动 BORE 调度器适配脚本 (最终修正版)
# ==============================================================================

set -e

# --- 配置项 ---
BORE_REPO_URL="https://github.com/firelzrd/bore-scheduler/archive/refs/heads/main.zip"
TEMP_DIR="./bore_temp"

# 【重要】根据用户要求，目录名绝对正确，不可修改
TKG_PATCH_DIR="./linux-tkg/linux-tkg-patches"
# 允许通过环境变量覆盖 CFG 文件路径
CFG_FILE="${CFG_FILE:-./customization.cfg}"

# --- 1. 获取并清洗内核版本 ---
if [ ! -f "$CFG_FILE" ]; then
    echo "❌ 错误: 未找到 $CFG_FILE (当前目录: $(pwd))"
    exit 1
fi

# 读取 _version，去除空格、引号
RAW_VER=$(grep '^_version=' "$CFG_FILE" | head -n 1 | sed 's/_version=//; s/"//g; s/^ *//; s/ *$//')

if [ -z "$RAW_VER" ]; then
    echo "⚠️ 警告: _version 为空。默认使用 eevdf。"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    exit 0
fi

echo "🔍 原始版本字符串: $RAW_VER"

# 提取主版本号 x.y
KERNEL_MAJOR_MINOR=$(echo "$RAW_VER" | sed 's/^v//' | grep -oE '[0-9]+\.[0-9]+' | head -n 1)

if [ -z "$KERNEL_MAJOR_MINOR" ]; then
    echo "❌ 错误: 无法从 '$RAW_VER' 中提取主版本号 (x.y)。默认使用 eevdf。"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    exit 0
fi

echo "✅ 检测到内核主版本: $KERNEL_MAJOR_MINOR"

# --- 2. 下载并解压 BORE ---
echo "📥 正在下载 BORE 源码..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

if ! wget -q "$BORE_REPO_URL" -O "$TEMP_DIR/bore.zip"; then
    echo "❌ 下载失败。回退到 eevdf。"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    rm -rf "$TEMP_DIR"
    exit 0
fi

echo "📦 正在解压..."
if ! unzip -q "$TEMP_DIR/bore.zip" -d "$TEMP_DIR"; then
    echo "❌ 解压失败。回退到 eevdf。"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    rm -rf "$TEMP_DIR"
    exit 0
fi

# 找到解压后的根目录
BORE_SRC_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "bore-scheduler-*" | head -n 1)

if [ -z "$BORE_SRC_DIR" ]; then
    echo "❌ 未找到源码目录。回退到 eevdf。"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    rm -rf "$TEMP_DIR"
    exit 0
fi

# --- 3. 查找对应版本的补丁 ---
TARGET_DIR="$BORE_SRC_DIR/patches/stable/linux-${KERNEL_MAJOR_MINOR}-bore"
LEGACY_DIR="$BORE_SRC_DIR/patches/legacy/linux-${KERNEL_MAJOR_MINOR}-bore"

PATCH_FILE=""

echo "🔎 正在查找目录: $TARGET_DIR"

if [ -d "$TARGET_DIR" ]; then
    PATCH_FILE=$(find "$TARGET_DIR" -name "0001*.patch" | head -n 1)
    if [ -n "$PATCH_FILE" ]; then
        echo "✅ 在 stable 目录找到补丁: $(basename $PATCH_FILE)"
    fi
fi

if [ -z "$PATCH_FILE" ] && [ -d "$LEGACY_DIR" ]; then
    echo "🔎 Stable 未找到，尝试 legacy 目录: $LEGACY_DIR"
    PATCH_FILE=$(find "$LEGACY_DIR" -name "0001*.patch" | head -n 1)
    if [ -n "$PATCH_FILE" ]; then
        echo "✅ 在 legacy 目录找到补丁: $(basename $PATCH_FILE)"
    fi
fi

# --- 4. 处理结果 ---
if [ -n "$PATCH_FILE" ]; then
    # 【重要】确保 TKG 补丁目录存在

    DEST_DIR="$TKG_PATCH_DIR/${KERNEL_MAJOR_MINOR}"
    mkdir -p "$DEST_DIR"

    # 复制并重命名核心补丁
    cp "$PATCH_FILE" "$DEST_DIR/0001-bore.patch"
    echo "📝 补丁已安装至: $DEST_DIR/0001-bore.patch"

    # 【关键】更新【当前目录】的 CFG
    sed -i 's|^_cpusched=.*|_cpusched="bore"|' "$CFG_FILE"
    echo "⚙️ 已更新customization: _cpusched=\"bore\""
else
    echo "⚠️ 未找到适用于内核 $KERNEL_MAJOR_MINOR 的 BORE 补丁。"
    echo "💡 回退到默认调度器: eevdf"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    echo "⚙️ 已更新customization: _cpusched=\"eevdf\""
fi

# --- 5. 清理 ---
rm -rf "$TEMP_DIR"
echo "✨ 完成。"
