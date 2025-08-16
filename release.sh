#!/bin/bash

# 版本发布脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -ne 1 ]; then
    echo -e "${RED}❌ 用法: $0 <version>${NC}"
    echo -e "${YELLOW}示例: $0 v1.0.0${NC}"
    exit 1
fi

VERSION="$1"

# 验证版本格式
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ 版本格式错误，应为 vX.Y.Z 格式${NC}"
    echo -e "${YELLOW}示例: v1.0.0${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 准备发布版本: $VERSION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查工作目录是否干净
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}❌ 工作目录不干净，请先提交所有更改${NC}"
    git status --short
    exit 1
fi

# 检查是否在主分支
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo -e "${YELLOW}⚠️  当前不在主分支 ($CURRENT_BRANCH)${NC}"
    read -p "$(echo -e ${YELLOW}是否继续？[y/N]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}取消发布${NC}"
        exit 0
    fi
fi

# 检查版本是否已存在
if git tag -l | grep -q "^$VERSION$"; then
    echo -e "${RED}❌ 版本 $VERSION 已存在${NC}"
    exit 1
fi

# 更新 Cargo.toml 版本
echo -e "${BLUE}📝 更新 Cargo.toml 版本...${NC}"
VERSION_NUMBER=${VERSION#v}  # 移除 v 前缀
sed -i.bak "s/^version = \".*\"/version = \"$VERSION_NUMBER\"/" Cargo.toml
rm -f Cargo.toml.bak

# 检查项目是否能正常编译
echo -e "${BLUE}🔨 检查项目编译...${NC}"
cargo check
echo -e "${GREEN}✅ 编译检查通过${NC}"

# 运行测试
echo -e "${BLUE}🧪 运行测试...${NC}"
cargo test
echo -e "${GREEN}✅ 测试通过${NC}"

# 提交版本更新
echo -e "${BLUE}📝 提交版本更新...${NC}"
git add Cargo.toml Cargo.lock
git commit -m "chore: bump version to $VERSION"

# 创建标签
echo -e "${BLUE}🏷️  创建版本标签...${NC}"
git tag -a "$VERSION" -m "Release $VERSION"

# 推送到远程
echo -e "${BLUE}📤 推送到远程仓库...${NC}"
git push origin "$CURRENT_BRANCH"
git push origin "$VERSION"

echo -e "\n${GREEN}🎉 版本 $VERSION 发布成功！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 后续步骤:${NC}"
echo -e "1. GitHub Action 将自动构建跨平台二进制文件"
echo -e "2. 检查 GitHub Actions 构建状态"
echo -e "3. 发布完成后，用户可以通过以下命令安装:"
echo -e "   ${GREEN}curl -fsSL https://raw.githubusercontent.com/\$REPO/main/install.sh | bash${NC}"
echo -e "\n${BLUE}🔗 相关链接:${NC}"
echo -e "   GitHub Actions: https://github.com/\$REPO/actions"
echo -e "   Releases: https://github.com/\$REPO/releases"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
