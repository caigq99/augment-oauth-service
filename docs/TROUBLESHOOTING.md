# Changelog 自动化故障排除指南

本文档帮助解决 Changelog 自动化工具的常见问题。

## 🔧 常见问题

### 1. GitHub Actions 工作流失败

**问题**: GitHub Actions 中的 "生成 Changelog" 步骤失败

**可能原因和解决方案**:

#### 权限问题
```yaml
# 确保工作流有正确的权限
permissions:
  contents: write
  pull-requests: write
```

#### 配置文件语法错误
```bash
# 本地验证配置文件
git-cliff --config cliff.toml --dry-run --verbose
```

#### Git 配置问题
```bash
# 检查 Git 配置
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
```

### 2. git-cliff 命令不存在

**问题**: `git-cliff: command not found`

**解决方案**:
```bash
# 安装 git-cliff
cargo install git-cliff

# 或使用包管理器 (Linux)
# Ubuntu/Debian
curl -LsSf https://github.com/orhun/git-cliff/releases/latest/download/git-cliff-installer.sh | sh

# macOS
brew install git-cliff
```

### 3. PowerShell 执行策略错误

**问题**: PowerShell 脚本无法执行

**解决方案**:
```powershell
# 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 或临时绕过
PowerShell -ExecutionPolicy Bypass -File .\scripts\changelog.ps1
```

### 4. 生成的 Changelog 为空

**问题**: 生成的 CHANGELOG.md 文件为空或只有标题

**可能原因**:
- 提交消息不符合 Conventional Commits 规范
- 没有符合条件的提交
- 配置文件过滤规则过于严格

**解决方案**:
```bash
# 检查提交历史
git log --oneline -10

# 使用详细模式查看处理过程
git-cliff --verbose --output CHANGELOG.md

# 检查配置文件中的过滤规则
cat cliff.toml | grep -A 5 "commit_parsers"
```

### 5. 配置文件语法错误

**问题**: `TOML parse error` 或配置文件无法解析

**解决方案**:
```bash
# 验证 TOML 语法
git-cliff --config cliff.toml --dry-run

# 检查常见语法问题:
# - 重复的键
# - 缺少引号
# - 错误的数组格式
```

### 6. 中文字符显示问题

**问题**: 生成的 Changelog 中中文字符显示为乱码

**解决方案**:
```bash
# 确保文件编码为 UTF-8
file -bi CHANGELOG.md

# Windows 用户可能需要设置代码页
chcp 65001
```

## 🧪 调试技巧

### 1. 详细输出模式

```bash
# 使用详细模式查看处理过程
git-cliff --verbose --output CHANGELOG.md

# 查看配置解析过程
git-cliff --config cliff.toml --verbose --dry-run
```

### 2. 测试特定范围

```bash
# 测试最近的提交
git-cliff --latest --output test.md

# 测试特定标签范围
git-cliff v1.0.0..v1.1.0 --output test.md

# 测试未发布的更改
git-cliff --unreleased --output test.md
```

### 3. 验证提交消息

```bash
# 查看最近的提交消息
git log --oneline -10

# 查看符合 conventional commits 的提交
git log --grep="^feat:" --grep="^fix:" --grep="^docs:" --oneline
```

### 4. 配置文件调试

```toml
# 在 cliff.toml 中添加调试配置
[git]
conventional_commits = true
filter_unconventional = false  # 包含非标准提交
```

## 🔍 手动验证步骤

### 1. 验证工具安装

```bash
# 检查 git-cliff 版本
git-cliff --version

# 检查 Git 版本
git --version

# 检查 Rust 版本 (如果从源码安装)
rustc --version
```

### 2. 验证配置文件

```bash
# 检查配置文件存在
ls -la cliff.toml

# 验证配置语法
git-cliff --config cliff.toml --dry-run

# 查看配置内容
cat cliff.toml
```

### 3. 验证 Git 仓库状态

```bash
# 检查 Git 仓库状态
git status

# 检查远程仓库
git remote -v

# 检查标签
git tag -l

# 检查分支
git branch -a
```

## 📋 测试清单

在报告问题之前，请完成以下测试：

- [ ] git-cliff 工具已正确安装
- [ ] cliff.toml 配置文件语法正确
- [ ] Git 仓库状态正常
- [ ] 有符合 Conventional Commits 规范的提交
- [ ] 本地可以手动生成 Changelog
- [ ] GitHub Actions 有正确的权限设置

## 🆘 获取帮助

如果以上步骤都无法解决问题，请提供以下信息：

1. **错误信息**: 完整的错误日志
2. **环境信息**: 操作系统、Git 版本、git-cliff 版本
3. **配置文件**: cliff.toml 的内容
4. **提交历史**: 最近 10 次提交的信息
5. **重现步骤**: 详细的操作步骤

### 收集调试信息

```bash
# 生成调试信息
echo "=== 环境信息 ===" > debug.log
git --version >> debug.log
git-cliff --version >> debug.log
echo "" >> debug.log

echo "=== 配置文件 ===" >> debug.log
cat cliff.toml >> debug.log
echo "" >> debug.log

echo "=== 最近提交 ===" >> debug.log
git log --oneline -10 >> debug.log
echo "" >> debug.log

echo "=== 详细输出 ===" >> debug.log
git-cliff --verbose --dry-run >> debug.log 2>&1
```

## 🔗 相关资源

- [git-cliff 官方文档](https://git-cliff.org/)
- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [TOML 语法指南](https://toml.io/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
