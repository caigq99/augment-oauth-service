#!/bin/bash

# 设置 Git Hooks 用于自动生成 Changelog

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
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo -e "${BLUE}🔧 设置 Git Hooks 用于自动生成 Changelog${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查是否在 Git 仓库中
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 创建 post-commit hook
echo -e "${BLUE}📝 创建 post-commit hook...${NC}"

cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash

# Post-commit hook: 自动生成 Changelog

# 检查是否安装了 git-cliff
if ! command -v git-cliff &> /dev/null; then
    echo "⚠️  git-cliff 未安装，跳过 Changelog 生成"
    exit 0
fi

# 检查是否有配置文件
if [ ! -f "cliff.toml" ]; then
    echo "⚠️  找不到 cliff.toml 配置文件，跳过 Changelog 生成"
    exit 0
fi

# 获取最新提交信息
LATEST_COMMIT=$(git log -1 --pretty=format:"%s")

# 跳过 changelog 相关的提交，避免无限循环
if [[ "$LATEST_COMMIT" == *"Changelog"* ]] || [[ "$LATEST_COMMIT" == *"changelog"* ]]; then
    echo "📄 跳过 Changelog 提交，避免无限循环"
    exit 0
fi

echo "🔄 自动生成 Changelog..."

# 生成 changelog (仅未发布的更改)
if git-cliff --unreleased --output CHANGELOG.md; then
    # 检查是否有更改
    if ! git diff --quiet CHANGELOG.md; then
        echo "✅ Changelog 已更新"
        
        # 询问是否自动提交 (在交互式环境中)
        if [ -t 1 ]; then
            echo "❓ 是否自动提交 Changelog 更改？ (y/N)"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                git add CHANGELOG.md
                git commit -m "docs: 自动更新 Changelog

- 基于最新提交自动生成
- 包含未发布的更改"
                echo "✅ Changelog 已自动提交"
            fi
        else
            echo "📄 Changelog 已更新，请手动提交"
        fi
    else
        echo "📄 Changelog 没有更改"
    fi
else
    echo "❌ Changelog 生成失败"
fi
EOF

# 使 hook 可执行
chmod +x "$HOOKS_DIR/post-commit"

echo -e "${GREEN}✅ post-commit hook 已创建${NC}"

# 创建 pre-push hook
echo -e "${BLUE}📝 创建 pre-push hook...${NC}"

cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash

# Pre-push hook: 推送前生成完整 Changelog

# 检查是否安装了 git-cliff
if ! command -v git-cliff &> /dev/null; then
    echo "⚠️  git-cliff 未安装，跳过 Changelog 生成"
    exit 0
fi

# 检查是否有配置文件
if [ ! -f "cliff.toml" ]; then
    echo "⚠️  找不到 cliff.toml 配置文件，跳过 Changelog 生成"
    exit 0
fi

echo "🔄 推送前生成完整 Changelog..."

# 生成完整的 changelog
if git-cliff --output CHANGELOG.md; then
    # 检查是否有更改
    if ! git diff --quiet CHANGELOG.md; then
        echo "✅ Changelog 已更新"
        
        # 在交互式环境中询问是否提交
        if [ -t 1 ]; then
            echo "❓ 检测到 Changelog 更改，是否提交后再推送？ (y/N)"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                git add CHANGELOG.md
                git commit -m "docs: 推送前更新完整 Changelog"
                echo "✅ Changelog 已提交，继续推送"
            else
                echo "⚠️  Changelog 有未提交的更改"
            fi
        else
            echo "📄 Changelog 已更新，但未提交"
        fi
    else
        echo "📄 Changelog 是最新的"
    fi
else
    echo "❌ Changelog 生成失败"
fi
EOF

# 使 hook 可执行
chmod +x "$HOOKS_DIR/pre-push"

echo -e "${GREEN}✅ pre-push hook 已创建${NC}"

# 创建卸载脚本
echo -e "${BLUE}📝 创建卸载脚本...${NC}"

cat > "$SCRIPT_DIR/remove-git-hooks.sh" << 'EOF'
#!/bin/bash

# 移除 Git Hooks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "🗑️  移除 Git Hooks..."

if [ -f "$HOOKS_DIR/post-commit" ]; then
    rm "$HOOKS_DIR/post-commit"
    echo "✅ 已移除 post-commit hook"
fi

if [ -f "$HOOKS_DIR/pre-push" ]; then
    rm "$HOOKS_DIR/pre-push"
    echo "✅ 已移除 pre-push hook"
fi

echo "🎉 Git Hooks 已移除"
EOF

chmod +x "$SCRIPT_DIR/remove-git-hooks.sh"

echo -e "${GREEN}✅ 卸载脚本已创建: scripts/remove-git-hooks.sh${NC}"

echo -e "\n${BLUE}🎉 Git Hooks 设置完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📋 已创建的 Hooks:${NC}"
echo -e "   • ${YELLOW}post-commit${NC}: 每次提交后自动生成未发布的 Changelog"
echo -e "   • ${YELLOW}pre-push${NC}: 推送前生成完整的 Changelog"
echo -e "\n${GREEN}🛠️  管理命令:${NC}"
echo -e "   • 移除 hooks: ${YELLOW}./scripts/remove-git-hooks.sh${NC}"
echo -e "   • 手动生成: ${YELLOW}./scripts/generate-changelog.sh${NC}"
echo -e "\n${GREEN}⚠️  注意事项:${NC}"
echo -e "   • Hooks 仅在交互式环境中询问是否自动提交"
echo -e "   • 避免 Changelog 提交的无限循环"
echo -e "   • 需要安装 git-cliff 工具"
