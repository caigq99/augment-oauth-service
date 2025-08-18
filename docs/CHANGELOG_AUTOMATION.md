# Changelog 自动化指南

本文档介绍如何使用集成的 changelog 自动化工具来管理项目的更新日志。

## 🔧 工具概述

项目集成了 `git-cliff` 工具，可以基于 Git 提交历史自动生成符合 [Keep a Changelog](https://keepachangelog.com/) 格式的更新日志。

### 核心特性

- 🔄 **自动生成**: 基于 Git 提交历史自动生成 changelog
- 📋 **标准格式**: 遵循 Keep a Changelog 格式规范
- 🏷️ **标签支持**: 基于 Git 标签自动分组版本
- 🎯 **智能解析**: 支持 Conventional Commits 规范
- 🛠️ **多平台**: 支持 Windows、Linux、macOS
- ⚙️ **可配置**: 通过 `cliff.toml` 自定义生成规则

## 📁 文件结构

```
augment-oauth-service/
├── cliff.toml                          # git-cliff 配置文件
├── CHANGELOG.md                        # 自动生成的更新日志
├── Makefile                           # Make 命令支持
├── scripts/
│   ├── changelog.ps1                  # PowerShell 脚本 (Windows)
│   ├── generate-changelog.sh          # Bash 脚本 (Linux/macOS)
│   ├── generate-changelog.ps1         # 详细 PowerShell 脚本
│   ├── setup-git-hooks.sh            # Git hooks 设置脚本
│   └── remove-git-hooks.sh            # Git hooks 移除脚本
└── .github/workflows/changelog.yml    # GitHub Actions 工作流
```

## 🚀 使用方法

### 1. 手动生成 Changelog

#### Windows (PowerShell)

```powershell
# 生成完整 changelog
.\scripts\changelog.ps1

# 生成未发布的更改
.\scripts\changelog.ps1 -Unreleased

# 生成到指定标签
.\scripts\changelog.ps1 -Tag v1.0.0

# 生成但不提交
.\scripts\changelog.ps1 -NoCommit
```

#### Linux/macOS (Bash)

```bash
# 生成完整 changelog
./scripts/generate-changelog.sh

# 使用 git-cliff 直接命令
git-cliff --output CHANGELOG.md
git-cliff --unreleased --output CHANGELOG.md
git-cliff --tag v1.0.0 --output CHANGELOG.md
```

#### 使用 Makefile (Linux/macOS)

```bash
# 生成完整 changelog
make changelog

# 生成未发布的更改
make changelog-unreleased

# 生成到指定标签
make changelog-tag TAG=v1.0.0

# 安装 git-cliff
make install-cliff
```

### 2. 自动化设置

#### Git Hooks 自动化

设置 Git hooks 在每次提交后自动更新 changelog：

```bash
# 设置 hooks
./scripts/setup-git-hooks.sh

# 移除 hooks
./scripts/remove-git-hooks.sh
```

**已创建的 Hooks:**
- `post-commit`: 每次提交后生成未发布的更改
- `pre-push`: 推送前生成完整的 changelog

#### GitHub Actions 自动化

项目包含 GitHub Actions 工作流 (`.github/workflows/changelog.yml`)，会在以下情况自动运行：

- 推送新标签时自动生成 changelog
- 手动触发工作流
- 支持指定标签或生成未发布更改

## ⚙️ 配置说明

### cliff.toml 配置文件

主要配置项：

```toml
[changelog]
header = "..."          # changelog 头部内容
body = "..."           # changelog 主体模板
footer = "..."         # changelog 底部内容

[git]
conventional_commits = true    # 启用 conventional commits 解析
tag_pattern = "v[0-9]*"       # 标签模式
commit_link_format = "..."    # 提交链接格式

[[git.commit_parsers]]
message = "^feat"             # 匹配 feat: 开头的提交
group = "新增"                # 分组为 "新增"
```

### 提交类型映射

| 提交类型 | 分组 | 说明 |
|----------|------|------|
| `feat:` | 新增 | 新功能 |
| `fix:` | 修复 | 问题修复 |
| `docs:` | 文档 | 文档更新 |
| `perf:` | 性能 | 性能优化 |
| `refactor:` | 重构 | 代码重构 |
| `test:` | 测试 | 测试相关 |
| `chore:` | 其他 | 构建、工具等 |
| `revert:` | 回滚 | 回滚更改 |

## 📝 最佳实践

### 1. 提交消息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**示例:**
```
feat(config): 添加智能端口管理功能

- 自动检测端口占用
- 端口被占用时自动查找可用端口
- 支持配置优先级管理

Closes #123
```

### 2. 版本标签规范

使用语义化版本标签：

```bash
# 主版本更新 (破坏性更改)
git tag -a v2.0.0 -m "Release v2.0.0: 重大更新"

# 次版本更新 (新功能)
git tag -a v1.1.0 -m "Release v1.1.0: 新增功能"

# 修订版本更新 (问题修复)
git tag -a v1.0.1 -m "Release v1.0.1: 问题修复"
```

### 3. 发布工作流

推荐的发布流程：

```bash
# 1. 完成开发和测试
git add .
git commit -m "feat: 新功能实现"

# 2. 生成 changelog
.\scripts\changelog.ps1

# 3. 创建版本标签
git tag -a v1.1.0 -m "Release v1.1.0"

# 4. 推送到远程
git push origin main
git push origin v1.1.0
```

## 🔍 故障排除

### 常见问题

**问题**: git-cliff 命令不存在
**解决**: 安装 git-cliff
```bash
cargo install git-cliff
```

**问题**: PowerShell 脚本执行策略错误
**解决**: 设置执行策略
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**问题**: 生成的 changelog 为空
**解决**: 检查提交消息是否符合 conventional commits 规范

**问题**: 配置文件语法错误
**解决**: 验证 `cliff.toml` 语法
```bash
git-cliff --config cliff.toml --dry-run
```

### 调试技巧

```bash
# 查看 git-cliff 版本
git-cliff --version

# 验证配置文件
git-cliff --config cliff.toml --dry-run

# 生成详细输出
git-cliff --verbose --output CHANGELOG.md

# 查看帮助
git-cliff --help
```

## 📚 相关资源

- [git-cliff 官方文档](https://git-cliff.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [语义化版本](https://semver.org/)

## 🎯 高级用法

### 自定义模板

可以在 `cliff.toml` 中自定义 changelog 模板：

```toml
[changelog]
body = """
{% if version %}\
    ## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{% else %}\
    ## [未发布]
{% endif %}\
{% for group, commits in commits | group_by(attribute="group") %}
    ### {{ group | striptags | trim | upper_first }}
    {% for commit in commits %}
        - {% if commit.scope %}**{{ commit.scope }}**: {% endif %}{{ commit.message | upper_first }}
    {% endfor %}
{% endfor %}\n
"""
```

### 过滤提交

可以配置过滤规则来排除特定提交：

```toml
[[git.commit_parsers]]
message = "^chore\\(release\\)"
skip = true

[[git.commit_parsers]]
message = "^Merge"
skip = true
```

### 生成特定范围

```bash
# 生成两个标签之间的更改
git-cliff v1.0.0..v1.1.0 --output CHANGELOG.md

# 生成最近 10 次提交
git-cliff --latest --output CHANGELOG.md
```
