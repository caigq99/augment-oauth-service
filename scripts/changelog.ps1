# Augment OAuth Service - Changelog Generator (Simplified)

param(
    [switch]$Unreleased,
    [string]$Tag,
    [switch]$NoCommit
)

Write-Host "Generating Changelog..." -ForegroundColor Blue

# Check if git-cliff is installed
try {
    git-cliff --version | Out-Null
} catch {
    Write-Host "git-cliff not found. Installing..." -ForegroundColor Yellow
    try {
        cargo install git-cliff
        Write-Host "git-cliff installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install git-cliff. Please install Rust first." -ForegroundColor Red
        exit 1
    }
}

# Build git-cliff command
$cliffArgs = @("--output", "CHANGELOG.md")

if ($Unreleased) {
    $cliffArgs += "--unreleased"
    Write-Host "Generating unreleased changes..." -ForegroundColor Yellow
}

if ($Tag) {
    $cliffArgs += "--tag", $Tag
    Write-Host "Generating up to tag: $Tag" -ForegroundColor Yellow
}

# Execute git-cliff
try {
    & git-cliff @cliffArgs
    Write-Host "Changelog generated successfully!" -ForegroundColor Green
    
    if (Test-Path "CHANGELOG.md") {
        $fileInfo = Get-Item "CHANGELOG.md"
        $fileSize = $fileInfo.Length
        $lineCount = (Get-Content "CHANGELOG.md" | Measure-Object -Line).Lines
        
        Write-Host "File size: $fileSize bytes" -ForegroundColor Blue
        Write-Host "Total lines: $lineCount" -ForegroundColor Blue
        
        if (-not $NoCommit) {
            $response = Read-Host "Commit changelog changes? (y/N)"
            if ($response -match "^[yY]") {
                try {
                    git add CHANGELOG.md
                    git commit -m "docs: auto-update changelog"
                    Write-Host "Changelog committed successfully!" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to commit changes" -ForegroundColor Yellow
                }
            }
        }
    }
    
} catch {
    Write-Host "Failed to generate changelog: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Done!" -ForegroundColor Blue
Write-Host "Usage examples:" -ForegroundColor Green
Write-Host "  .\scripts\changelog.ps1                    # Generate full changelog" -ForegroundColor Yellow
Write-Host "  .\scripts\changelog.ps1 -Unreleased        # Generate unreleased only" -ForegroundColor Yellow
Write-Host "  .\scripts\changelog.ps1 -Tag v1.0.0        # Generate up to tag" -ForegroundColor Yellow
Write-Host "  .\scripts\changelog.ps1 -NoCommit          # Don't ask to commit" -ForegroundColor Yellow
