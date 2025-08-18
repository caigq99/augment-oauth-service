# 开发指南

本文档为 Augment OAuth Service 的开发者提供详细的开发环境搭建、代码结构说明和贡献指南。

## 开发环境搭建

### 前置要求

- **Rust**: 1.70+ (推荐使用最新稳定版)
- **Git**: 用于版本控制
- **curl**: 用于测试 API

### 安装 Rust

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 重新加载环境变量
source ~/.cargo/env

# 验证安装
rustc --version
cargo --version
```

### 克隆项目

```bash
git clone https://github.com/caigq99/augment-oauth-service.git
cd augment-oauth-service
```

### 开发工具安装

```bash
# 安装开发工具
cargo install cargo-watch  # 文件变化自动重启
cargo install cargo-edit    # 依赖管理
cargo install cargo-audit   # 安全审计
```

## 项目结构详解

```
augment-oauth-service/
├── Cargo.toml              # 项目配置和依赖
├── .env                    # 开发环境变量 (可选)
├── src/
│   ├── main.rs            # 程序入口，服务器启动逻辑
│   ├── config.rs          # 配置管理模块
│   ├── handlers.rs        # HTTP 请求处理器
│   ├── models.rs          # 数据模型定义
│   ├── oauth.rs           # OAuth 核心逻辑
│   └── middleware.rs      # 中间件和错误处理
├── docs/                  # 文档目录
│   ├── CONFIGURATION.md   # 配置指南
│   ├── DEPLOYMENT.md      # 部署指南
│   └── DEVELOPMENT.md     # 开发指南
├── start.sh              # 开发启动脚本
├── install.sh            # 安装脚本
└── README.md             # 项目说明
```

### 核心模块说明

#### `src/main.rs`

- 应用程序入口点
- 配置加载和验证
- 智能端口管理
- 路由设置和服务器启动

#### `src/config.rs`

- 配置管理核心模块
- 环境变量和配置文件解析
- 端口可用性检测
- 配置优先级处理

#### `src/handlers.rs`

- HTTP 请求处理器
- API 端点实现
- 请求验证和响应格式化

#### `src/models.rs`

- 数据结构定义
- 序列化/反序列化配置
- API 请求/响应模型

#### `src/oauth.rs`

- OAuth 2.0 PKCE 流程实现
- 状态管理和验证
- Token 交换逻辑

#### `src/middleware.rs`

- 错误处理中间件
- 统一响应格式
- 日志记录

## 开发工作流

### 1. 开发环境启动

```bash
# 方式一：使用 cargo-watch 自动重启
cargo watch -x run

# 方式二：使用启动脚本
./scripts/start.sh

# 方式三：直接运行
cargo run
```

### 2. 配置开发环境

创建 `.env` 文件：

```bash
# .env
RUST_LOG=debug
PORT=3000
HOST=127.0.0.1
OAUTH_AUTH_URL=https://auth.augmentcode.com/authorize
OAUTH_CLIENT_ID=v
STATE_EXPIRE_MINUTES=60
```

### 3. 测试 API

```bash
# 健康检查
curl http://127.0.0.1:3000/health

# 获取授权链接
curl "http://127.0.0.1:3000/api/auth-url?user_id=test"

# 完成授权 (需要真实的授权码)
curl -X POST "http://127.0.0.1:3000/api/complete-auth" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "test_code",
    "state": "test_state",
    "tenant_url": "https://test.augmentcode.com/"
  }'
```

## 代码规范

### Rust 代码风格

使用 `rustfmt` 格式化代码：

```bash
cargo fmt
```

使用 `clippy` 进行代码检查：

```bash
cargo clippy
```

### 提交规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
feat: 添加端口自动检测功能
fix: 修复配置文件读取问题
docs: 更新 API 文档
refactor: 重构错误处理逻辑
test: 添加配置模块单元测试
```

### 代码注释

```rust
/// 检查端口是否可用
///
/// # 参数
/// * `host` - 主机地址
/// * `port` - 端口号
///
/// # 返回值
/// * `true` - 端口可用
/// * `false` - 端口被占用
pub fn is_port_available(host: &str, port: u16) -> bool {
    // 实现逻辑...
}
```

## 测试

### 运行测试

```bash
# 运行所有测试
cargo test

# 运行特定模块测试
cargo test config

# 运行测试并显示输出
cargo test -- --nocapture

# 运行测试覆盖率
cargo install cargo-tarpaulin
cargo tarpaulin --out Html
```

### 编写测试

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_port_availability() {
        assert!(is_port_available("127.0.0.1", 0));
    }

    #[tokio::test]
    async fn test_config_loading() {
        let config = AppConfig::load().unwrap();
        assert_eq!(config.server.host, "0.0.0.0");
    }
}
```

## 性能优化

### 编译优化

```toml
# Cargo.toml
[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"
```

### 内存使用优化

- 使用 `Arc` 共享数据
- 避免不必要的克隆
- 合理使用生命周期

### 并发优化

- 使用 `DashMap` 进行并发访问
- 异步处理 I/O 操作
- 避免阻塞操作

## 调试技巧

### 日志调试

```rust
use tracing::{debug, info, warn, error};

debug!("详细调试信息: {:?}", data);
info!("一般信息: {}", message);
warn!("警告信息: {}", warning);
error!("错误信息: {}", error);
```

### 环境变量调试

```bash
# 设置详细日志
RUST_LOG=trace cargo run

# 设置特定模块日志
RUST_LOG=augment_oauth_service::config=debug cargo run
```

### 使用调试器

```bash
# 安装 rust-gdb
rustup component add rust-src

# 使用 gdb 调试
rust-gdb target/debug/augment-oauth-service
```

## 依赖管理

### 添加依赖

```bash
# 添加运行时依赖
cargo add tokio --features full

# 添加开发依赖
cargo add --dev mockito

# 添加构建依赖
cargo add --build cc
```

### 更新依赖

```bash
# 更新所有依赖
cargo update

# 检查过时依赖
cargo outdated

# 安全审计
cargo audit
```

## 发布流程

### 版本管理

1. 更新 `Cargo.toml` 中的版本号
2. 更新 `CHANGELOG.md`
3. 创建 Git 标签
4. 推送到远程仓库

```bash
# 更新版本
cargo edit set-version 1.1.0

# 提交更改
git add .
git commit -m "chore: bump version to 1.1.0"

# 创建标签
git tag v1.1.0

# 推送
git push origin main --tags
```

### 构建发布版本

```bash
# 构建优化版本
cargo build --release

# 交叉编译 (需要安装目标平台)
cargo build --release --target x86_64-pc-windows-gnu
```

## 贡献指南

### 提交 Pull Request

1. Fork 项目
2. 创建功能分支
3. 编写代码和测试
4. 确保所有测试通过
5. 提交 Pull Request

### 代码审查清单

- [ ] 代码符合项目规范
- [ ] 添加了必要的测试
- [ ] 更新了相关文档
- [ ] 通过了所有测试
- [ ] 没有引入安全问题

## 常见问题

### 编译错误

**问题**: 依赖版本冲突
**解决**: 使用 `cargo tree` 查看依赖树，更新冲突的依赖

**问题**: 链接错误
**解决**: 检查系统依赖，安装必要的开发包

### 运行时错误

**问题**: 端口绑定失败
**解决**: 检查端口是否被占用，服务会自动查找可用端口

**问题**: 配置文件读取失败
**解决**: 检查文件路径和权限，确保格式正确

## 资源链接

- [Rust 官方文档](https://doc.rust-lang.org/)
- [Tokio 文档](https://tokio.rs/)
- [Axum 文档](https://docs.rs/axum/)
- [Tracing 文档](https://docs.rs/tracing/)
