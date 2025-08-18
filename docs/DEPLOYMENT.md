# 部署指南

本文档提供了 Augment OAuth Service 的详细部署指南，包括不同环境的部署方式和最佳实践。

## 快速部署

### 🚀 一键安装（推荐）

支持 Linux 和 macOS 系统的一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/caigq99/augment-oauth-service/main/install.sh | bash
```

安装完成后服务将自动启动在 `http://localhost:3000`

### 📦 手动下载部署

1. **下载二进制文件**

从 [Releases](https://github.com/caigq99/augment-oauth-service/releases) 页面下载：

```bash
# Linux x86_64
curl -L -o augment-oauth-service \
  https://github.com/caigq99/augment-oauth-service/releases/latest/download/augment-oauth-service-linux-x86_64
chmod +x augment-oauth-service

# macOS ARM64 (Apple Silicon)
curl -L -o augment-oauth-service \
  https://github.com/caigq99/augment-oauth-service/releases/latest/download/augment-oauth-service-macos-aarch64
chmod +x augment-oauth-service

# Windows x86_64
# 下载 augment-oauth-service-windows-x86_64.exe
```

2. **配置服务**

创建配置文件：
```bash
# 创建配置目录
sudo mkdir -p /etc/augment-oauth

# 创建配置文件
sudo tee /etc/augment-oauth/config.env << EOF
PORT=3000
HOST=0.0.0.0
RUST_LOG=info
OAUTH_AUTH_URL=https://auth.augmentcode.com/authorize
OAUTH_CLIENT_ID=v
STATE_EXPIRE_MINUTES=30
EOF
```

3. **启动服务**

```bash
./augment-oauth-service
```

## 系统服务部署

### Linux (systemd)

1. **创建服务文件**

```bash
sudo tee /etc/systemd/system/augment-oauth-service.service << EOF
[Unit]
Description=Augment OAuth Service
Documentation=https://github.com/caigq99/augment-oauth-service
After=network.target
Wants=network.target

[Service]
Type=simple
User=augment
Group=augment
ExecStart=/usr/local/bin/augment-oauth-service
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=augment-oauth-service
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
EnvironmentFile=/etc/augment-oauth/config.env

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/augment-oauth

[Install]
WantedBy=multi-user.target
EOF
```

2. **创建用户和目录**

```bash
# 创建服务用户
sudo useradd -r -s /bin/false -d /nonexistent augment

# 创建日志目录
sudo mkdir -p /var/log/augment-oauth
sudo chown augment:augment /var/log/augment-oauth
```

3. **启动和管理服务**

```bash
# 重载 systemd 配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start augment-oauth-service

# 开机自启
sudo systemctl enable augment-oauth-service

# 查看状态
sudo systemctl status augment-oauth-service

# 查看日志
sudo journalctl -u augment-oauth-service -f
```

### macOS (launchd)

1. **创建 plist 文件**

```bash
tee ~/Library/LaunchAgents/com.augment.oauth-service.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.augment.oauth-service</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/augment-oauth-service</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/augment-oauth/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/augment-oauth/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>RUST_LOG</key>
        <string>info</string>
        <key>PORT</key>
        <string>3000</string>
    </dict>
</dict>
</plist>
EOF
```

2. **启动服务**

```bash
# 加载服务
launchctl load ~/Library/LaunchAgents/com.augment.oauth-service.plist

# 卸载服务
launchctl unload ~/Library/LaunchAgents/com.augment.oauth-service.plist
```

## Docker 部署

### 创建 Dockerfile

```dockerfile
FROM debian:bookworm-slim

# 安装必要的依赖
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建用户
RUN useradd -r -s /bin/false -d /nonexistent augment

# 复制二进制文件
COPY augment-oauth-service /usr/local/bin/
RUN chmod +x /usr/local/bin/augment-oauth-service

# 切换用户
USER augment

# 暴露端口
EXPOSE 3000

# 启动服务
CMD ["/usr/local/bin/augment-oauth-service"]
```

### 构建和运行

```bash
# 构建镜像
docker build -t augment-oauth-service .

# 运行容器
docker run -d \
  --name augment-oauth \
  -p 3000:3000 \
  -e RUST_LOG=info \
  -e PORT=3000 \
  -e HOST=0.0.0.0 \
  augment-oauth-service

# 查看日志
docker logs -f augment-oauth
```

### Docker Compose

```yaml
version: '3.8'

services:
  augment-oauth:
    image: augment-oauth-service
    container_name: augment-oauth
    ports:
      - "3000:3000"
    environment:
      - RUST_LOG=info
      - PORT=3000
      - HOST=0.0.0.0
      - OAUTH_AUTH_URL=https://auth.augmentcode.com/authorize
      - OAUTH_CLIENT_ID=v
      - STATE_EXPIRE_MINUTES=30
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 反向代理配置

### Nginx

```nginx
server {
    listen 80;
    server_name oauth.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Apache

```apache
<VirtualHost *:80>
    ServerName oauth.yourdomain.com
    
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/
</VirtualHost>
```

## 监控和日志

### 健康检查

```bash
# 检查服务状态
curl http://localhost:3000/health

# 预期响应
{
  "success": true,
  "data": {
    "status": "ok",
    "service": "augment-oauth-service",
    "timestamp": "2025-01-01T00:00:00Z"
  },
  "message": "服务运行正常"
}
```

### 日志管理

**systemd 日志：**
```bash
# 查看实时日志
sudo journalctl -u augment-oauth-service -f

# 查看最近的日志
sudo journalctl -u augment-oauth-service --since "1 hour ago"

# 查看错误日志
sudo journalctl -u augment-oauth-service -p err
```

**文件日志：**
```bash
# 配置日志输出到文件
RUST_LOG=info ./augment-oauth-service 2>&1 | tee /var/log/augment-oauth.log
```

## 安全建议

1. **使用专用用户运行服务**
2. **限制文件权限**
3. **配置防火墙规则**
4. **定期更新服务版本**
5. **监控服务状态和日志**
6. **使用 HTTPS（通过反向代理）**

## 故障排除

### 常见问题

1. **端口被占用**: 服务会自动查找可用端口
2. **权限不足**: 确保用户有执行权限
3. **配置文件错误**: 检查配置文件格式和路径
4. **网络问题**: 检查防火墙和网络配置

### 卸载服务

```bash
# 使用一键卸载脚本
curl -fsSL https://raw.githubusercontent.com/caigq99/augment-oauth-service/main/uninstall.sh | bash
```
