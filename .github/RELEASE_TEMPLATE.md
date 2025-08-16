# Augment OAuth Service v{VERSION}

## 🚀 新功能
- OAuth 2.0 PKCE 流程实现
- 统一API响应格式
- 跨平台二进制文件发布
- 一键部署脚本

## 🔧 改进
- 性能优化
- 错误处理改进
- 日志记录增强

## 🐛 修复
- 修复已知问题

## 📦 下载

选择适合您平台的二进制文件：

| 平台 | 架构 | 下载链接 |
|------|------|----------|
| Linux | x86_64 | [augment-oauth-service-linux-x86_64](https://github.com/{REPO}/releases/download/v{VERSION}/augment-oauth-service-linux-x86_64) |
| Linux | ARM64 | [augment-oauth-service-linux-aarch64](https://github.com/{REPO}/releases/download/v{VERSION}/augment-oauth-service-linux-aarch64) |
| macOS | x86_64 | [augment-oauth-service-macos-x86_64](https://github.com/{REPO}/releases/download/v{VERSION}/augment-oauth-service-macos-x86_64) |
| macOS | ARM64 | [augment-oauth-service-macos-aarch64](https://github.com/{REPO}/releases/download/v{VERSION}/augment-oauth-service-macos-aarch64) |
| Windows | x86_64 | [augment-oauth-service-windows-x86_64.exe](https://github.com/{REPO}/releases/download/v{VERSION}/augment-oauth-service-windows-x86_64.exe) |

## 🛠️ 快速安装

### 一键安装 (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/{REPO}/main/install.sh | bash
```

### 手动安装

```bash
# Linux x86_64
curl -L -o augment-oauth-service https://github.com/{REPO}/releases/download/v{VERSION}/augment-oauth-service-linux-x86_64
chmod +x augment-oauth-service
./augment-oauth-service

# macOS ARM64
curl -L -o augment-oauth-service https://github.com/{REPO}/releases/download/v{VERSION}/augment-oauth-service-macos-aarch64
chmod +x augment-oauth-service
./augment-oauth-service
```

## 🔐 校验和

下载后请验证文件完整性：

```bash
# 下载校验和文件
curl -L -O https://github.com/{REPO}/releases/download/v{VERSION}/checksums-augment-oauth-service-linux-x86_64.txt

# 验证文件
sha256sum -c checksums-augment-oauth-service-linux-x86_64.txt
```

## 📋 API 文档

### 统一返回格式

所有API都使用统一的返回格式：

```json
{
  "success": true,
  "data": { /* 业务数据 */ },
  "message": "操作描述"
}
```

### 主要接口

- `GET /health` - 健康检查
- `GET /api/auth-url` - 获取授权链接
- `POST /api/complete-auth` - 完成授权

## 🔧 服务管理

### Linux (systemd)
```bash
sudo systemctl start augment-oauth-service
sudo systemctl status augment-oauth-service
sudo journalctl -u augment-oauth-service -f
```

### macOS (launchd)
```bash
launchctl load ~/Library/LaunchAgents/com.augment.oauth-service.plist
tail -f /var/log/augment-oauth/stdout.log
```

## 🗑️ 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/{REPO}/main/uninstall.sh | bash
```

## 📖 更多信息

- [完整文档](https://github.com/{REPO}/blob/main/README.md)
- [问题反馈](https://github.com/{REPO}/issues)
- [贡献指南](https://github.com/{REPO}/blob/main/CONTRIBUTING.md)

---

**完整更新日志**: https://github.com/{REPO}/compare/v{PREV_VERSION}...v{VERSION}
