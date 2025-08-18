# Augment OAuth Service - 自动生成 Changelog 脚本 (PowerShell 版本)

param(
    [switch]$Unreleased,
    [string]$Tag,
    [switch]$NoCommit
)

# 颜色函数
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

Write-ColorText "🔄 自动生成 Changelog" "Blue"
Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"

# 获取脚本目录和项目根目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# 切换到项目根目录
Set-Location $ProjectRoot

# 检查是否在 Git 仓库中
try {
    git rev-parse --git-dir | Out-Null
} catch {
    Write-ColorText "❌ 当前目录不是 Git 仓库" "Red"
    exit 1
}

# 检查是否有配置文件
if (-not (Test-Path "cliff.toml")) {
    Write-ColorText "❌ 找不到 cliff.toml 配置文件" "Red"
    exit 1
}

# 检查是否安装了 git-cliff
$gitCliffInstalled = $false
try {
    git-cliff --version | Out-Null
    $gitCliffInstalled = $true
} catch {
    Write-ColorText "⚠️  git-cliff 未安装，正在安装..." "Yellow"
    
    # 检查是否安装了 Cargo
    try {
        cargo --version | Out-Null
        Write-ColorText "📦 使用 Cargo 安装 git-cliff..." "Blue"
        cargo install git-cliff
        $gitCliffInstalled = $true
        Write-ColorText "✅ git-cliff 安装完成" "Green"
    } catch {
        Write-ColorText "❌ 请先安装 Rust 和 Cargo" "Red"
        Write-ColorText "💡 访问: https://rustup.rs/" "Yellow"
        exit 1
    }
}

if (-not $gitCliffInstalled) {
    Write-ColorText "❌ git-cliff 安装失败" "Red"
    exit 1
}

Write-ColorText "📋 生成 Changelog..." "Blue"

# 构建 git-cliff 命令
$cliffArgs = @("--output", "CHANGELOG.md")

if ($Unreleased) {
    $cliffArgs += "--unreleased"
    Write-ColorText "📝 生成未发布的更改..." "Yellow"
}

if ($Tag) {
    $cliffArgs += "--tag", $Tag
    Write-ColorText "🏷️  生成到标签: $Tag" "Yellow"
}

# 执行 git-cliff
try {
    & git-cliff @cliffArgs
    Write-ColorText "✅ Changelog 生成成功" "Green"
    Write-ColorText "📄 文件位置: CHANGELOG.md" "Green"
    
    # 显示文件信息
    if (Test-Path "CHANGELOG.md") {
        $fileInfo = Get-Item "CHANGELOG.md"
        $fileSize = $fileInfo.Length
        $lineCount = (Get-Content "CHANGELOG.md" | Measure-Object -Line).Lines
        
        Write-ColorText "📊 文件大小: $fileSize 字节" "Blue"
        Write-ColorText "📏 总行数: $lineCount 行" "Blue"
        
        # 询问是否查看生成的内容
        Write-ColorText "`n❓ 是否查看生成的 Changelog？ (y/N)" "Yellow"
        $response = Read-Host
        if ($response -match "^[yY]") {
            Write-ColorText "`n📖 Changelog 内容预览:" "Blue"
            Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
            Get-Content "CHANGELOG.md" | Select-Object -First 50
            if ($lineCount -gt 50) {
                Write-ColorText "`n... (显示前 50 行，完整内容请查看 CHANGELOG.md)" "Yellow"
            }
        }
        
        # 询问是否提交更改
        if (-not $NoCommit) {
            Write-ColorText "`n❓ 是否提交 Changelog 更改？ (y/N)" "Yellow"
            $commitResponse = Read-Host
            if ($commitResponse -match "^[yY]") {
                try {
                    git add CHANGELOG.md
                    git commit -m "docs: 自动更新 Changelog"
                    Write-ColorText "✅ Changelog 已提交" "Green"
                } catch {
                    Write-ColorText "⚠️  没有检测到更改或提交失败" "Yellow"
                }
            }
        }
    }
    
} catch {
    Write-ColorText "❌ Changelog 生成失败: $($_.Exception.Message)" "Red"
    exit 1
}

Write-ColorText "`n🎉 操作完成！" "Blue"
Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
Write-ColorText "📝 使用说明:" "Green"
Write-ColorText "   • 手动生成: git-cliff --output CHANGELOG.md" "Yellow"
Write-ColorText "   • 生成未发布: git-cliff --unreleased --output CHANGELOG.md" "Yellow"
Write-ColorText "   • 生成特定版本: git-cliff --tag v1.0.0 --output CHANGELOG.md" "Yellow"
Write-ColorText "   • PowerShell 脚本: .\scripts\generate-changelog.ps1" "Yellow"
Write-ColorText "   • 查看帮助: git-cliff --help" "Yellow"
