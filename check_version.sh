#!/bin/bash
set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== 🕵️ 检查最新内核版本 (Kernel.org) ===${NC}"

CFG_FILE="customization.cfg"
if [ ! -f "$CFG_FILE" ]; then
    echo -e "${RED}❌ 错误: 未找到本地 $CFG_FILE${NC}"
    exit 1
fi

# 1. 获取当前本地配置的版本
CURRENT_VER=$(grep '^_version=' "$CFG_FILE" | head -n 1 | sed 's/_version=//; s/"//g; s/^ *//; s/ *$//')
echo "📄 本地配置文件版本: ${CURRENT_VER}"

# 2. 从 kernel.org 获取最新的 Tag
echo "🌐 正在查询 kernel.org 最新标签..."

# 获取主线最新 tag (包含 rc)
LATEST_TAG=$(git ls-remote --tags --sort="-v:refname" https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git | grep -oP 'refs/tags/v[0-9]+\.[0-9]+(-rc[0-9]+)?$' | head -n 1 | sed 's|refs/tags/||')

if [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}❌ 错误: 无法从 kernel.org 获取最新版本标签${NC}"
    exit 1
fi

# 去掉开头的 'v'，例如 v6.13-rc5 -> 6.13-rc5
TARGET_VERSION="${LATEST_TAG#v}"

echo -e "${GREEN}✅ 检测到最新内核版本: ${TARGET_VERSION}${NC}"

# 3. 比较版本
FORCE_BUILD="${{ github.event.inputs.force_build }}"

if [ "$CURRENT_VER" == "$TARGET_VERSION" ] && [ "$FORCE_BUILD" != "true" ]; then
    echo -e "${GREEN}✨ 版本已是最新 (${CURRENT_VER})，跳过构建。${NC}"
    echo "SKIP_BUILD=true" >> $GITHUB_ENV
    echo "VERSION_CHANGED=false" >> $GITHUB_ENV
else
    echo -e "${YELLOW}🚀 版本变更或强制构建！(${CURRENT_VER} -> ${TARGET_VERSION})${NC}"
    
    # 4. 更新本地 cfg
    sed -i "s|^_version=.*|_version=\"${TARGET_VERSION}\"|" "$CFG_FILE"
    echo -e "${GREEN}📝 已更新本地 $CFG_FILE 中的 _version 为 ${TARGET_VERSION}${NC}"

    echo "SKIP_BUILD=false" >> $GITHUB_ENV
    echo "VERSION_CHANGED=true" >> $GITHUB_ENV
    echo "NEW_VERSION=${TARGET_VERSION}" >> $GITHUB_ENV
fi