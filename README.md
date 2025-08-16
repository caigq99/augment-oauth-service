# Augment OAuth Service

一个使用Rust构建的Augment OAuth认证服务，实现了OAuth 2.0 PKCE流程。

## 功能特性

- 🔐 OAuth 2.0 PKCE (Proof Key for Code Exchange) 流程
- 🚀 高性能异步处理
- 🛡️ 安全的状态管理
- 📝 详细的日志记录
- 🌐 CORS支持
- ⚡ 内存状态存储

## 统一返回格式

所有API都使用统一的返回格式：

### 成功响应
```json
{
  "success": true,
  "data": {
    // 具体的业务数据
  },
  "message": "操作成功描述"
}
```

### 错误响应
```json
{
  "success": false,
  "data": {},
  "message": "错误信息描述"
}
```

## API接口

### 1. 获取授权链接

**GET** `/api/auth-url`

获取Augment OAuth授权链接。

**查询参数：**
- `user_id` (可选): 用户标识

**响应示例：**
```json
{
  "success": true,
  "data": {
    "authorize_url": "https://auth.augmentcode.com/authorize?response_type=code&code_challenge=xxx&client_id=v&state=xxx&prompt=login",
    "state": "random_state_value"
  },
  "message": "授权链接生成成功"
}
```

### 2. 完成授权

**POST** `/api/complete-auth`

使用授权码完成OAuth流程并获取访问令牌。

**请求体：**
```json
{
  "code": "authorization_code_from_callback",
  "state": "state_value_from_step1",
  "tenant_url": "https://your-tenant.augmentcode.com/"
}
```

**成功响应示例：**
```json
{
  "success": true,
  "data": {
    "status": "success",
    "token": "access_token_value",
    "tenant_url": "https://your-tenant.augmentcode.com/",
    "token_info": {
      "id": "uuid-generated-id",
      "created_at": "2025-01-01T00:00:00Z"
    }
  },
  "message": "OAuth授权完成成功"
}
```

**错误响应示例：**
```json
{
  "success": false,
  "data": {},
  "message": "无效的请求数据: code, state, tenant_url 都是必需的"
}
```

### 3. 健康检查

**GET** `/health`

检查服务状态。

**响应示例：**
```json
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

## 快速开始

### 🚀 一键部署 (推荐)

支持 Linux 和 macOS 系统的一键安装，自动创建守护进程：

```bash
# 一键安装并启动服务
curl -fsSL https://raw.githubusercontent.com/caigq99/augment-oauth-service/main/install.sh | bash

# 服务将自动启动在 http://localhost:3000
curl http://localhost:3000/health
```

### 📦 手动下载二进制文件

从 [Releases](https://github.com/caigq99/augment-oauth-service/releases) 页面下载适合您平台的二进制文件：

```bash
# Linux x86_64
curl -L -o augment-oauth-service https://github.com/caigq99/augment-oauth-service/releases/latest/download/augment-oauth-service-linux-x86_64
chmod +x augment-oauth-service
./augment-oauth-service

# macOS ARM64 (Apple Silicon)
curl -L -o augment-oauth-service https://github.com/caigq99/augment-oauth-service/releases/latest/download/augment-oauth-service-macos-aarch64
chmod +x augment-oauth-service
./augment-oauth-service

# Windows x86_64
# 下载 augment-oauth-service-windows-x86_64.exe 并运行
```

### 🛠️ 从源码编译

确保您已安装Rust (1.70+)：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cd augment-oauth-service
cargo build --release
./target/release/augment-oauth-service
```

### 🔧 开发模式

```bash
# 监听文件变化自动重启
cargo install cargo-watch
cargo watch -x run

# 或使用提供的启动脚本
./start.sh
```

## 使用示例

### 完整的OAuth流程

```bash
# 1. 获取授权链接
curl -X GET "http://localhost:3000/api/auth-url?user_id=test_user"

# 响应:
# {
#   "success": true,
#   "data": {
#     "authorize_url": "https://auth.augmentcode.com/authorize?...",
#     "state": "abc123"
#   },
#   "message": "授权链接生成成功"
# }

# 2. 用户访问authorize_url进行授权，获取到code

# 3. 完成授权
curl -X POST "http://localhost:3000/api/complete-auth" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "received_authorization_code",
    "state": "abc123",
    "tenant_url": "https://your-tenant.augmentcode.com/"
  }'

# 成功响应:
# {
#   "success": true,
#   "data": {
#     "status": "success",
#     "token": "access_token_value",
#     "tenant_url": "https://your-tenant.augmentcode.com/",
#     "token_info": {
#       "id": "uuid",
#       "created_at": "2025-01-01T00:00:00Z"
#     }
#   },
#   "message": "OAuth授权完成成功"
# }

# 错误响应示例:
# {
#   "success": false,
#   "data": {},
#   "message": "Token交换失败: ..."
# }
```

## 项目结构

```
augment-oauth-service/
├── Cargo.toml          # 项目依赖配置
├── src/
│   ├── main.rs         # 主程序入口
│   ├── handlers.rs     # HTTP处理器
│   ├── models.rs       # 数据模型
│   └── oauth.rs        # OAuth服务逻辑
└── README.md           # 项目说明
```

## 技术栈

- **Axum**: 现代化的Rust Web框架
- **Tokio**: 异步运行时
- **Serde**: 序列化/反序列化
- **Reqwest**: HTTP客户端
- **DashMap**: 并发安全的HashMap
- **UUID**: 唯一标识符生成
- **SHA2**: 加密哈希
- **Base64**: 编码/解码

## 安全特性

- **PKCE流程**: 防止授权码拦截攻击
- **State验证**: 防止CSRF攻击
- **状态过期**: OAuth状态30分钟自动过期
- **内存存储**: 状态信息仅存储在内存中

## 配置

服务默认配置：
- 监听地址: `0.0.0.0:3000`
- OAuth状态过期时间: 30分钟
- 授权服务器: `https://auth.augmentcode.com`
- 客户端ID: `v`

## 错误处理

所有错误响应都遵循统一格式：

```json
{
  "success": false,
  "error": "错误描述",
  "details": "详细错误信息(可选)"
}
```

常见错误码：
- `400`: 请求参数错误
- `500`: 服务器内部错误

## 日志

服务使用结构化日志，包含：
- 请求处理日志
- OAuth流程日志
- 错误详情日志
- 性能指标日志

## 服务管理

### Linux (systemd)

```bash
# 查看服务状态
sudo systemctl status augment-oauth-service

# 启动/停止/重启服务
sudo systemctl start augment-oauth-service
sudo systemctl stop augment-oauth-service
sudo systemctl restart augment-oauth-service

# 查看日志
sudo journalctl -u augment-oauth-service -f

# 开机自启
sudo systemctl enable augment-oauth-service
```

### macOS (launchd)

```bash
# 启动服务
launchctl load ~/Library/LaunchAgents/com.augment.oauth-service.plist

# 停止服务
launchctl unload ~/Library/LaunchAgents/com.augment.oauth-service.plist

# 查看日志
tail -f /var/log/augment-oauth/stdout.log
```

### 卸载服务

```bash
# 一键卸载
curl -fsSL https://raw.githubusercontent.com/caigq99/augment-oauth-service/main/uninstall.sh | bash
```

## 配置

### 环境变量

```bash
# 服务配置
RUST_LOG=info          # 日志级别 (trace, debug, info, warn, error)
PORT=3000              # 监听端口
HOST=0.0.0.0           # 监听地址

# OAuth 配置
OAUTH_AUTH_URL=https://auth.augmentcode.com/authorize
OAUTH_CLIENT_ID=v
STATE_EXPIRE_MINUTES=30
```

### 配置文件

安装后的配置文件位置：`/etc/augment-oauth/config.env`

## 发布流程

### 创建新版本

```bash
# 发布新版本 (自动构建跨平台二进制文件)
./release.sh v1.0.0
```

### GitHub Actions

推送标签后，GitHub Actions 将自动：
1. 构建 Linux (x86_64, ARM64) 二进制文件
2. 构建 macOS (x86_64, ARM64) 二进制文件
3. 构建 Windows (x86_64) 二进制文件
4. 生成 SHA256 校验和
5. 创建 GitHub Release
6. 上传所有构建产物

### 支持的平台

- **Linux**: x86_64, ARM64
- **macOS**: x86_64 (Intel), ARM64 (Apple Silicon)
- **Windows**: x86_64

## 许可证

MIT License
