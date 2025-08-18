# 配置指南

Augment OAuth Service 提供了灵活的配置选项，支持多种配置方式和智能端口管理。

## 配置优先级

配置按以下优先级顺序加载（高优先级覆盖低优先级）：

1. **环境变量** (最高优先级)
2. **配置文件** (.env, /etc/augment-oauth/config.env)
3. **默认值** (最低优先级)

## 智能端口管理

### 端口自动检测功能

服务启动时会自动检测配置的端口是否可用：

- ✅ **端口可用**: 直接使用配置的端口
- ⚠️ **端口被占用**: 自动查找下一个可用端口（最多扫描100个端口）
- ❌ **无可用端口**: 服务启动失败并显示错误信息

### 端口检测日志

**端口可用时：**
```
INFO augment_oauth_service: 配置信息: 主机=0.0.0.0, 端口=3000
INFO augment_oauth_service::config: 端口 3000 可用，使用配置的端口
INFO augment_oauth_service: 服务地址: http://0.0.0.0:3000
```

**端口被占用时：**
```
INFO augment_oauth_service: 配置信息: 主机=0.0.0.0, 端口=3000
WARN augment_oauth_service::config: 端口 3000 已被占用，正在查找可用端口...
INFO augment_oauth_service::config: 找到可用端口: 3001
INFO augment_oauth_service: 服务地址: http://0.0.0.0:3001
```

## 配置参数

### 服务器配置

| 参数 | 环境变量 | 默认值 | 说明 |
|------|----------|--------|------|
| 主机地址 | `HOST` | `0.0.0.0` | 服务监听的IP地址 |
| 端口 | `PORT` | `3000` | 服务监听的端口号 |
| 日志级别 | `RUST_LOG` | `info` | 日志输出级别 |

### OAuth 配置

| 参数 | 环境变量 | 默认值 | 说明 |
|------|----------|--------|------|
| 授权服务器 | `OAUTH_AUTH_URL` | `https://auth.augmentcode.com/authorize` | OAuth 授权服务器地址 |
| 客户端ID | `OAUTH_CLIENT_ID` | `v` | OAuth 客户端标识符 |
| 状态过期时间 | `STATE_EXPIRE_MINUTES` | `30` | OAuth 状态过期时间（分钟） |

### 日志级别说明

- `trace`: 最详细的日志，包含所有调试信息
- `debug`: 调试信息，用于开发和问题排查
- `info`: 一般信息，包含重要的运行状态
- `warn`: 警告信息，可能的问题但不影响运行
- `error`: 错误信息，严重问题需要关注

## 配置方式

### 1. 环境变量配置

**临时设置（当次运行有效）：**
```bash
PORT=8080 HOST=127.0.0.1 RUST_LOG=debug ./augment-oauth-service
```

**永久设置（添加到 shell 配置文件）：**
```bash
# ~/.bashrc 或 ~/.zshrc
export PORT=8080
export HOST=127.0.0.1
export RUST_LOG=debug
```

### 2. .env 文件配置

在项目根目录创建 `.env` 文件：

```bash
# .env
# 服务器配置
PORT=8080
HOST=127.0.0.1
RUST_LOG=debug

# OAuth 配置
OAUTH_AUTH_URL=https://auth.augmentcode.com/authorize
OAUTH_CLIENT_ID=v
STATE_EXPIRE_MINUTES=30
```

### 3. 系统配置文件

**Linux 系统：**
```bash
# /etc/augment-oauth/config.env
PORT=3000
HOST=0.0.0.0
RUST_LOG=info
OAUTH_AUTH_URL=https://auth.augmentcode.com/authorize
OAUTH_CLIENT_ID=v
STATE_EXPIRE_MINUTES=30
```

**macOS 系统：**
```bash
# /usr/local/etc/augment-oauth/config.env
PORT=3000
HOST=0.0.0.0
RUST_LOG=info
```

## 配置示例

### 开发环境配置

```bash
# .env
PORT=3000
HOST=127.0.0.1
RUST_LOG=debug
STATE_EXPIRE_MINUTES=60
```

### 生产环境配置

```bash
# /etc/augment-oauth/config.env
PORT=3000
HOST=0.0.0.0
RUST_LOG=info
STATE_EXPIRE_MINUTES=30
```

### 测试环境配置

```bash
# 使用环境变量
PORT=8080 HOST=127.0.0.1 RUST_LOG=trace ./augment-oauth-service
```

## 配置验证

启动服务时，会在日志中显示当前使用的配置：

```
INFO augment_oauth_service: Augment OAuth Service 正在启动...
INFO augment_oauth_service: 配置信息: 主机=127.0.0.1, 端口=8080
INFO augment_oauth_service::config: 端口 8080 可用，使用配置的端口
INFO augment_oauth_service: Augment OAuth Service 启动成功！
INFO augment_oauth_service: 服务地址: http://127.0.0.1:8080
INFO augment_oauth_service: 健康检查: http://127.0.0.1:8080/health
```

## 故障排除

### 端口相关问题

**问题**: 服务无法启动，提示端口被占用
**解决**: 服务会自动查找可用端口，检查日志中的实际端口号

**问题**: 需要使用特定端口
**解决**: 停止占用该端口的其他服务，或使用环境变量指定其他端口

### 配置文件问题

**问题**: 配置文件不生效
**解决**: 检查文件路径和权限，确保格式正确

**问题**: 环境变量不生效
**解决**: 确保环境变量名称正确，重启终端或重新加载配置

### 权限问题

**问题**: 无法绑定到低端口号（< 1024）
**解决**: 使用 sudo 运行或配置更高的端口号
