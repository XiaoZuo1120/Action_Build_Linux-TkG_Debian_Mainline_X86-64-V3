#!/bin/bash

# ==============================================================================
# 自动 BORE 调度器适配脚本（支持自定义 Base64 / URL 补丁）
# ==============================================================================

set -e

# --- 配置项 ---
BORE_REPO_URL="https://github.com/firelzrd/bore-scheduler/archive/refs/heads/main.zip"
TEMP_DIR="./bore_temp"

# 【重要】根据用户要求，目录名绝对正确，不可修改
TKG_PATCH_DIR="./linux-tkg/linux-tkg-patches"
# 允许通过环境变量覆盖 CFG 文件路径
CFG_FILE="${CFG_FILE:-./customization.cfg}"

# --- 新增：自定义 BORE 补丁输入（Base64 或 URL）---
# 可通过环境变量 CUSTOM_BORE_PATCH 传入
CUSTOM_BORE_PATCH="${CUSTOM_BORE_PATCH:-}"

# 判断输入是 Base64 还是 URL，并落地为 patch 文件
# 参数1: 输入字符串；参数2: 输出 patch 路径
resolve_custom_patch() {
    local input="$1"
    local output="$2"

    # 去除首尾空白
    input="$(echo "$input" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

    if [ -z "$input" ]; then
        return 1
    fi

    # URL 判断：http:// 或 https:// 开头
    if echo "$input" | grep -qE '^https?://'; then
        echo "🌐 检测到 URL，正在下载自定义补丁..."
        if ! curl -fsSL "$input" -o "$output"; then
            echo "❌ 自定义补丁下载失败: $input"
            return 1
        fi
    else
        # 否则按 Base64 处理
        echo "🔐 检测到 Base64，正在解码自定义补丁..."
        # 兼容 URL-safe Base64 和可能缺失的 padding
        local b64
        b64="$(echo "$input" | tr '_-' '/+')"
        # 补齐 padding
        while [ $(( ${#b64} % 4 )) -ne 0 ]; do
            b64="${b64}="
        done
        if ! echo "$b64" | base64 -d > "$output" 2>/dev/null; then
            echo "❌ Base64 解码失败。"
            rm -f "$output"
            return 1
        fi
    fi

    # 简单校验：patch 文件应包含 diff 头
    if ! grep -qE '^(diff --git|--- |\+\+\+ )' "$output" 2>/dev/null; then
        echo "⚠️ 警告: 自定义补丁内容不像标准 patch 文件，仍将尝试应用。"
    fi

    echo "✅ 自定义补丁已准备: $output"
    return 0
}

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

# 只提取主次版本号 x.y
KERNEL_MAJOR_MINOR=$(echo "$RAW_VER" | sed 's/^v//' | grep -oE '[0-9]+\.[0-9]+' | head -n 1)

if [ -z "$KERNEL_MAJOR_MINOR" ]; then
    echo "❌ 错误: 无法从 '$RAW_VER' 中提取主次版本号 (x.y)。默认使用 eevdf。"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    exit 0
fi

echo "✅ 检测到内核主次版本: $KERNEL_MAJOR_MINOR"

# --- 2. 自定义补丁优先 ---
if [ -n "$CUSTOM_BORE_PATCH" ]; then
    echo "🎯 使用用户自定义 BORE 补丁。"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    CUSTOM_PATCH_FILE="$TEMP_DIR/custom-bore.patch"

    if resolve_custom_patch "$CUSTOM_BORE_PATCH" "$CUSTOM_PATCH_FILE"; then
        DEST_DIR="$TKG_PATCH_DIR/${KERNEL_MAJOR_MINOR}"
        mkdir -p "$DEST_DIR"
        cp "$CUSTOM_PATCH_FILE" "$DEST_DIR/0001-bore.patch"
        echo "📝 自定义补丁已安装至: $DEST_DIR/0001-bore.patch"

        sed -i 's|^_cpusched=.*|_cpusched="bore"|' "$CFG_FILE"
        echo "⚙️ 已更新customization: _cpusched=\"bore\""
        rm -rf "$TEMP_DIR"
        echo "✨ 完成（自定义补丁）。"
        exit 0
    else
        echo "⚠️ 自定义补丁处理失败，回退到自动搜索流程。"
        rm -rf "$TEMP_DIR"
    fi
fi

# --- 3. 下载并解压 BORE ---
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

# --- 4. 模糊版本搜索补丁 ---
STABLE_DIR="$BORE_SRC_DIR/patches/stable"
LEGACY_DIR="$BORE_SRC_DIR/patches/legacy"

PATCH_FILE=""

# 4.1 在 stable 扁平目录中模糊匹配: 0001-linux${KERNEL_MAJOR_MINOR}*-bore-*.patch
if [ -d "$STABLE_DIR" ]; then
    echo "🔎 在 stable 目录中模糊搜索 linux-${KERNEL_MAJOR_MINOR}* 补丁..."
    PATCH_FILE=$(find "$STABLE_DIR" -maxdepth 1 -type f -name "0001-linux${KERNEL_MAJOR_MINOR}*-bore-*.patch" | head -n 1)
    if [ -n "$PATCH_FILE" ]; then
        echo "✅ 在 stable 目录找到补丁: $(basename "$PATCH_FILE")"
    fi
fi

# 4.2 如果 stable 未找到，回退到 legacy 的 linux-x.y-bore 子目录
if [ -z "$PATCH_FILE" ] && [ -d "$LEGACY_DIR" ]; then
    LEGACY_TARGET_DIR="$LEGACY_DIR/linux-${KERNEL_MAJOR_MINOR}-bore"
    echo "🔎 在 legacy 目录中搜索: $LEGACY_TARGET_DIR"
    if [ -d "$LEGACY_TARGET_DIR" ]; then
        PATCH_FILE=$(find "$LEGACY_TARGET_DIR" -maxdepth 1 -type f -name "0001*.patch" | head -n 1)
        if [ -n "$PATCH_FILE" ]; then
            echo "✅ 在 legacy 目录找到补丁: $(basename "$PATCH_FILE")"
        fi
    fi
fi

# --- 5. 处理结果 ---
if [ -n "$PATCH_FILE" ]; then
    DEST_DIR="$TKG_PATCH_DIR/${KERNEL_MAJOR_MINOR}"
    mkdir -p "$DEST_DIR"

    cp "$PATCH_FILE" "$DEST_DIR/0001-bore.patch"
    echo "📝 补丁已安装至: $DEST_DIR/0001-bore.patch"

    sed -i 's|^_cpusched=.*|_cpusched="bore"|' "$CFG_FILE"
    echo "⚙️ 已更新customization: _cpusched=\"bore\""
else
    echo "⚠️ 未找到适用于内核 $KERNEL_MAJOR_MINOR 的 BORE 补丁。"
    echo "💡 回退到默认调度器: eevdf"
    sed -i 's|^_cpusched=.*|_cpusched="eevdf"|' "$CFG_FILE"
    echo "⚙️ 已更新customization: _cpusched=\"eevdf\""
fi

# --- 6. 清理 ---
rm -rf "$TEMP_DIR"
echo "✨ 完成。"
