#!/bin/bash
# check_version-gcc-stable.sh
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
CFG_FILE="customization-gcc-stable.cfg"

echo -e "${YELLOW}=== 🕵️ Check Latest Stable Kernel (GCC) ===${NC}"

if [ ! -f "$CFG_FILE" ]; then echo -e "${RED}❌ Missing $CFG_FILE${NC}"; exit 1; fi

CURRENT_VER=$(grep '^_version=' "$CFG_FILE" | head -n 1 | sed 's/_version=//; s/"//g; s/^ *//; s/ *$//')
echo "📄 Local Version: ${CURRENT_VER:-<empty>}"

# 从 gregkh/linux 获取最新稳定标签 (排除 RC)
LATEST_TAG=$(git ls-remote --tags --sort="-v:refname" https://github.com/gregkh/linux.git | \
             grep -oP 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | \
             grep -v '\-rc' | \
             head -n 1 | \
             sed 's|refs/tags/||')

if [ -z "$LATEST_TAG" ]; then echo -e "${RED}❌ Failed to fetch tag${NC}"; exit 1; fi

TARGET_VERSION="${LATEST_TAG}"
echo -e "${GREEN}✅ Latest Stable: ${TARGET_VERSION}${NC}"

FORCE_BUILD="${FORCE_BUILD:-false}"
if [ "$CURRENT_VER" == "$TARGET_VERSION" ] && [ "$FORCE_BUILD" != "true" ]; then
    echo -e "${GREEN}✨ Up-to-date. Skipping.${NC}"
    echo "SKIP_BUILD=true" >> $GITHUB_ENV
    echo "VERSION_CHANGED=false" >> $GITHUB_ENV
else
    echo -e "${YELLOW}🚀 Update detected! (${CURRENT_VER} -> ${TARGET_VERSION})${NC}"
    sed -i "s|^_version=.*|_version=\"${TARGET_VERSION}\"|" "$CFG_FILE"
    echo "SKIP_BUILD=false" >> $GITHUB_ENV
    echo "VERSION_CHANGED=true" >> $GITHUB_ENV
    echo "NEW_VERSION=${TARGET_VERSION}" >> $GITHUB_ENV
fi