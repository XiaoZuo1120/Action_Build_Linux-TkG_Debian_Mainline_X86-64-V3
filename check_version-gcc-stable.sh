#!/bin/bash
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${YELLOW}=== 🕵️ 检查最新稳定内核版本 (GCC-Stable) ===${NC}"

CFG_FILE="customization-gcc-stable.cfg" # 【修改】指向 GCC 稳定版 cfg
if [ ! -f "$CFG_FILE" ]; then echo -e "${RED}❌ 错误: 未找到 $CFG_FILE${NC}"; exit 1; fi

CURRENT_VER=$(grep '^_version=' "$CFG_FILE" | head -n 1 | sed 's/_version=//; s/"//g; s/^ *//; s/ *$//')
echo "📄 本地配置文件版本: ${CURRENT_VER:-<空>}"

echo "🌐 正在查询 gregkh/linux 最新稳定标签..."
LATEST_TAG=$(git ls-remote --tags --sort="-v:refname" https://github.com/gregkh/linux.git | \
             grep -oP 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | \
             grep -v '\-rc' | \
             head -n 1 | \
             sed 's|refs/tags/||')

if [ -z "$LATEST_TAG" ]; then echo -e "${RED}❌ 错误: 无法获取标签${NC}"; exit 1; fi
TARGET_VERSION="${LATEST_TAG}"
echo -e "${GREEN}✅ 检测到最新稳定内核版本: ${TARGET_VERSION}${NC}"

FORCE_BUILD="${FORCE_BUILD:-false}"
if [ "$CURRENT_VER" == "$TARGET_VERSION" ] && [ "$FORCE_BUILD" != "true" ]; then
    echo -e "${GREEN}✨ 版本已是最新，跳过。${NC}"
    echo "SKIP_BUILD=true" >> $GITHUB_ENV
    echo "VERSION_CHANGED=false" >> $GITHUB_ENV
else
    echo -e "${YELLOW}🚀 版本变更！(${CURRENT_VER} -> ${TARGET_VERSION})${NC}"
    sed -i "s|^_version=.*|_version=\"${TARGET_VERSION}\"|" "$CFG_FILE"
    echo "SKIP_BUILD=false" >> $GITHUB_ENV
    echo "VERSION_CHANGED=true" >> $GITHUB_ENV
    echo "NEW_VERSION=${TARGET_VERSION}" >> $GITHUB_ENV
fi