#!/bin/bash
set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== 🕵️ 检查最新稳定内核版本 (gregkh/linux) ===${NC}"

CFG_FILE="customization-stable.cfg"
if [ ! -f "$CFG_FILE" ]; then
    echo -e "${RED}❌ 错误: 未找到本地 $CFG_FILE${NC}"
    exit 1
fi

# 1. 获取当前本地配置的版本
CURRENT_VER=$(grep '^_version=' "$CFG_FILE" | head -n 1 | sed 's/_version=//; s/"//g; s/^ *//; s/ *$//')
echo "📄 本地配置文件版本: ${CURRENT_VER:-<空>}"

# 2. 从 Greg KH 仓库获取最新的稳定 Tag (排除 RC)
echo "🌐 正在查询 gregkh/linux 最新稳定标签..."

# 【关键】
# 1. --sort="-v:refname": 按版本逻辑倒序排列
# 2. grep -oP 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$': 
#    - 强制要求存在第三位小版本号 (.Z)，这天然排除了像 v7.1 这样的主标签
#    - [0-9]+ 可以匹配 1 位、2 位或 3 位数字 (如 .1, .11, .175)
# 3. grep -v '\-rc': 双重保险，排除任何包含 -rc 的标签
# 4. head -n 1: 取最新版
LATEST_TAG=$(git ls-remote --tags --sort="-v:refname" https://github.com/gregkh/linux.git | \
             grep -oP 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | \
             grep -v '\-rc' | \
             head -n 1 | \
             sed 's|refs/tags/||')

if [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}❌ 错误: 无法从 gregkh/linux 获取最新稳定版本标签${NC}"
    exit 1
fi

TARGET_VERSION="${LATEST_TAG}"

echo -e "${GREEN}✅ 检测到最新稳定内核版本: ${TARGET_VERSION}${NC}"

# 3. 比较版本
FORCE_BUILD="${FORCE_BUILD:-false}"

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