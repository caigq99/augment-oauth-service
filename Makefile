# Augment OAuth Service - Makefile

.PHONY: help changelog changelog-unreleased changelog-tag install-cliff setup-hooks remove-hooks build test clean release

# 默认目标
help: ## 显示帮助信息
	@echo "🔧 Augment OAuth Service - 开发工具"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📋 Changelog 相关:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(changelog|cliff|hooks)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🛠️  构建和测试:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(build|test|clean|release)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "💡 使用示例:"
	@echo "  make changelog          # 生成完整 changelog"
	@echo "  make changelog-unreleased # 生成未发布的更改"
	@echo "  make changelog-tag TAG=v1.2.0 # 生成到指定标签"

# Changelog 相关目标
changelog: install-cliff ## 生成完整的 changelog
	@echo "🔄 生成完整 Changelog..."
	@git-cliff --output CHANGELOG.md
	@echo "✅ Changelog 生成完成: CHANGELOG.md"

changelog-unreleased: install-cliff ## 生成未发布的更改
	@echo "🔄 生成未发布的更改..."
	@git-cliff --unreleased --output CHANGELOG.md
	@echo "✅ 未发布的更改已生成: CHANGELOG.md"

changelog-tag: install-cliff ## 生成到指定标签 (使用 TAG=v1.0.0)
	@if [ -z "$(TAG)" ]; then \
		echo "❌ 请指定标签: make changelog-tag TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "🔄 生成到标签 $(TAG)..."
	@git-cliff --tag $(TAG) --output CHANGELOG.md
	@echo "✅ Changelog 生成完成到标签 $(TAG): CHANGELOG.md"

install-cliff: ## 安装 git-cliff 工具
	@if command -v git-cliff >/dev/null 2>&1; then \
		echo "✅ git-cliff 已安装"; \
	else \
		echo "📦 安装 git-cliff..."; \
		if command -v cargo >/dev/null 2>&1; then \
			cargo install git-cliff; \
		else \
			echo "❌ 请先安装 Rust: https://rustup.rs/"; \
			exit 1; \
		fi; \
	fi

setup-hooks: ## 设置 Git hooks 自动生成 changelog
	@echo "🔧 设置 Git hooks..."
	@chmod +x scripts/setup-git-hooks.sh
	@./scripts/setup-git-hooks.sh

remove-hooks: ## 移除 Git hooks
	@echo "🗑️  移除 Git hooks..."
	@if [ -f scripts/remove-git-hooks.sh ]; then \
		chmod +x scripts/remove-git-hooks.sh; \
		./scripts/remove-git-hooks.sh; \
	else \
		echo "❌ 卸载脚本不存在"; \
	fi

# 构建和测试目标
build: ## 构建项目
	@echo "🔨 构建项目..."
	@cargo build

build-release: ## 构建发布版本
	@echo "🔨 构建发布版本..."
	@cargo build --release

test: ## 运行测试
	@echo "🧪 运行测试..."
	@cargo test

test-verbose: ## 运行详细测试
	@echo "🧪 运行详细测试..."
	@cargo test -- --nocapture

clean: ## 清理构建文件
	@echo "🧹 清理构建文件..."
	@cargo clean

# 发布相关目标
release: build-release test ## 构建发布版本并运行测试
	@echo "🚀 准备发布..."
	@echo "✅ 构建和测试完成"

tag-release: ## 创建发布标签 (使用 VERSION=v1.0.0)
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ 请指定版本: make tag-release VERSION=v1.0.0"; \
		exit 1; \
	fi
	@echo "🏷️  创建标签 $(VERSION)..."
	@git tag -a $(VERSION) -m "Release $(VERSION)"
	@echo "✅ 标签 $(VERSION) 已创建"
	@echo "💡 推送标签: git push origin $(VERSION)"

# 开发工具
dev: ## 启动开发服务器
	@echo "🚀 启动开发服务器..."
	@cargo run

dev-watch: ## 启动开发服务器 (自动重启)
	@echo "🚀 启动开发服务器 (自动重启)..."
	@if command -v cargo-watch >/dev/null 2>&1; then \
		cargo watch -x run; \
	else \
		echo "❌ 请安装 cargo-watch: cargo install cargo-watch"; \
		exit 1; \
	fi

format: ## 格式化代码
	@echo "🎨 格式化代码..."
	@cargo fmt

lint: ## 代码检查
	@echo "🔍 代码检查..."
	@cargo clippy

check: format lint test ## 完整检查 (格式化 + 检查 + 测试)
	@echo "✅ 完整检查完成"

# 文档相关
docs: ## 生成文档
	@echo "📚 生成文档..."
	@cargo doc --open

# 安装和卸载
install: build-release ## 安装到系统
	@echo "📦 安装到系统..."
	@cargo install --path .

uninstall: ## 从系统卸载
	@echo "🗑️  从系统卸载..."
	@cargo uninstall augment-oauth-service

# 工具检查
check-tools: ## 检查开发工具
	@echo "🔧 检查开发工具..."
	@echo -n "Rust: "; if command -v rustc >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi
	@echo -n "Cargo: "; if command -v cargo >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi
	@echo -n "git-cliff: "; if command -v git-cliff >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi
	@echo -n "cargo-watch: "; if command -v cargo-watch >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi

# 项目信息
info: ## 显示项目信息
	@echo "📋 项目信息"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "项目名称: Augment OAuth Service"
	@echo "版本: $(shell grep '^version' Cargo.toml | cut -d'"' -f2)"
	@echo "Rust 版本: $(shell rustc --version 2>/dev/null || echo '未安装')"
	@echo "Git 分支: $(shell git branch --show-current 2>/dev/null || echo '未知')"
	@echo "最新标签: $(shell git describe --tags --abbrev=0 2>/dev/null || echo '无标签')"
	@echo "提交数量: $(shell git rev-list --count HEAD 2>/dev/null || echo '未知')"
