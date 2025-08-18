#!/bin/bash

# Augment OAuth Service - 自动生成 Changelog 脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🔄 自动生成 Changelog${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查是否安装了 git-cliff
if ! command -v git-cliff &> /dev/null; then
    echo -e "${YELLOW}⚠️  git-cliff 未安装，正在安装...${NC}"
    
    # 检测操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v cargo &> /dev/null; then
            cargo install git-cliff
        else
            echo -e "${RED}❌ 请先安装 Rust 和 Cargo${NC}"
            echo -e "${YELLOW}💡 安装命令: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install git-cliff
        elif command -v cargo &> /dev/null; then
            cargo install git-cliff
        else
            echo -e "${RED}❌ 请先安装 Homebrew 或 Rust${NC}"
            echo -e "${YELLOW}💡 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
            exit 1
        fi
    else
        # Windows 或其他系统
        if command -v cargo &> /dev/null; then
            cargo install git-cliff
        else
            echo -e "${RED}❌ 请先安装 Rust 和 Cargo${NC}"
            echo -e "${YELLOW}💡 访问: https://rustup.rs/${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ git-cliff 安装完成${NC}"
fi

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 检查是否有配置文件
if [ ! -f "cliff.toml" ]; then
    echo -e "${RED}❌ 找不到 cliff.toml 配置文件${NC}"
    exit 1
fi

echo -e "${BLUE}📋 生成 Changelog...${NC}"

# 生成 changelog
if git-cliff --output CHANGELOG.md; then
    echo -e "${GREEN}✅ Changelog 生成成功${NC}"
    echo -e "${GREEN}📄 文件位置: CHANGELOG.md${NC}"
    
    # 显示文件大小
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        file_size=$(stat -f%z CHANGELOG.md)
    else
        # Linux
        file_size=$(stat -c%s CHANGELOG.md)
    fi
    
    echo -e "${BLUE}📊 文件大小: ${file_size} 字节${NC}"
    
    # 显示行数
    line_count=$(wc -l < CHANGELOG.md)
    echo -e "${BLUE}📏 总行数: ${line_count} 行${NC}"
    
    # 询问是否查看生成的内容
    echo -e "\n${YELLOW}❓ 是否查看生成的 Changelog？ (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "\n${BLUE}📖 Changelog 内容预览:${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        head -50 CHANGELOG.md
        if [ $line_count -gt 50 ]; then
            echo -e "\n${YELLOW}... (显示前 50 行，完整内容请查看 CHANGELOG.md)${NC}"
        fi
    fi
    
    # 询问是否提交更改
    echo -e "\n${YELLOW}❓ 是否提交 Changelog 更改？ (y/N)${NC}"
    read -r commit_response
    if [[ "$commit_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if git add CHANGELOG.md && git commit -m "docs: 自动更新 Changelog"; then
            echo -e "${GREEN}✅ Changelog 已提交${NC}"
        else
            echo -e "${YELLOW}⚠️  没有检测到更改或提交失败${NC}"
        fi
    fi
    
else
    echo -e "${RED}❌ Changelog 生成失败${NC}"
    exit 1
fi

echo -e "\n${BLUE}🎉 操作完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📝 使用说明:${NC}"
echo -e "   • 手动生成: ${YELLOW}git-cliff --output CHANGELOG.md${NC}"
echo -e "   • 生成未发布: ${YELLOW}git-cliff --unreleased --output CHANGELOG.md${NC}"
echo -e "   • 生成特定版本: ${YELLOW}git-cliff --tag v1.0.0 --output CHANGELOG.md${NC}"
echo -e "   • 查看帮助: ${YELLOW}git-cliff --help${NC}"
