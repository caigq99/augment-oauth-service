use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use std::env;
use std::net::{SocketAddr, TcpListener};
use tracing::{debug, info, warn};

/// 应用配置结构
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    /// 服务器配置
    pub server: ServerConfig,
    /// OAuth配置
    pub oauth: OAuthConfig,
}

/// 服务器配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    /// 监听主机地址
    pub host: String,
    /// 监听端口
    pub port: u16,
    /// 日志级别
    pub log_level: String,
}

/// OAuth配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OAuthConfig {
    /// 授权服务器URL
    pub auth_url: String,
    /// 客户端ID
    pub client_id: String,
    /// 状态过期时间（分钟）
    pub state_expire_minutes: u32,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            server: ServerConfig {
                host: "0.0.0.0".to_string(),
                port: 3000,
                log_level: "info".to_string(),
            },
            oauth: OAuthConfig {
                auth_url: "https://auth.augmentcode.com/authorize".to_string(),
                client_id: "v".to_string(),
                state_expire_minutes: 30,
            },
        }
    }
}

impl AppConfig {
    /// 从环境变量和配置文件加载配置
    pub fn load() -> Result<Self> {
        let mut config = Self::default();

        // 首先尝试从环境变量加载
        config.load_from_env()?;

        // 然后尝试从配置文件加载（如果存在）
        if let Err(e) = config.load_from_file() {
            debug!("无法加载配置文件: {}", e);
        }

        // 再次从环境变量加载，确保环境变量优先级最高
        config.load_from_env()?;

        info!("配置加载完成: {:?}", config);
        Ok(config)
    }

    /// 从环境变量加载配置
    fn load_from_env(&mut self) -> Result<()> {
        // 加载 .env 文件（如果存在）
        if let Err(e) = dotenvy::dotenv() {
            debug!("无法加载 .env 文件: {}", e);
        }

        // 服务器配置
        if let Ok(host) = env::var("HOST") {
            self.server.host = host;
        }

        if let Ok(port_str) = env::var("PORT") {
            self.server.port = port_str
                .parse()
                .map_err(|e| anyhow!("无效的端口号 '{}': {}", port_str, e))?;
        }

        if let Ok(log_level) = env::var("RUST_LOG") {
            self.server.log_level = log_level;
        }

        // OAuth配置
        if let Ok(auth_url) = env::var("OAUTH_AUTH_URL") {
            self.oauth.auth_url = auth_url;
        }

        if let Ok(client_id) = env::var("OAUTH_CLIENT_ID") {
            self.oauth.client_id = client_id;
        }

        if let Ok(expire_str) = env::var("STATE_EXPIRE_MINUTES") {
            self.oauth.state_expire_minutes = expire_str
                .parse()
                .map_err(|e| anyhow!("无效的过期时间 '{}': {}", expire_str, e))?;
        }

        Ok(())
    }

    /// 从配置文件加载配置
    fn load_from_file(&mut self) -> Result<()> {
        // 尝试多个可能的配置文件路径
        let config_paths = ["/etc/augment-oauth/config.env", "./config.env", "./.env"];

        for path in &config_paths {
            if std::path::Path::new(path).exists() {
                info!("从配置文件加载配置: {}", path);
                dotenvy::from_path(path)?;
                return Ok(());
            }
        }

        Err(anyhow!("未找到配置文件"))
    }

    /// 获取服务器监听地址
    pub fn server_addr(&self) -> String {
        format!("{}:{}", self.server.host, self.server.port)
    }
}

/// 检查端口是否可用
pub fn is_port_available(host: &str, port: u16) -> bool {
    // 尝试绑定到指定的地址和端口
    let addr = format!("{}:{}", host, port);
    match TcpListener::bind(&addr) {
        Ok(listener) => {
            // 成功绑定，端口可用
            drop(listener); // 立即释放
            true
        }
        Err(_) => {
            // 绑定失败，端口被占用
            false
        }
    }
}

/// 查找可用端口
pub fn find_available_port(host: &str, start_port: u16, max_attempts: u16) -> Result<u16> {
    for port in start_port..(start_port + max_attempts) {
        if is_port_available(host, port) {
            return Ok(port);
        }
    }

    Err(anyhow!(
        "在端口范围 {}-{} 内未找到可用端口",
        start_port,
        start_port + max_attempts - 1
    ))
}

/// 获取可用的服务器地址
pub async fn get_available_server_addr(config: &mut AppConfig) -> Result<SocketAddr> {
    let host = &config.server.host;
    let original_port = config.server.port;

    // 首先检查配置的端口是否可用
    if is_port_available(host, original_port) {
        info!("端口 {} 可用，使用配置的端口", original_port);
        let addr = format!("{}:{}", host, original_port).parse()?;
        return Ok(addr);
    }

    // 如果配置的端口不可用，查找下一个可用端口
    warn!("端口 {} 已被占用，正在查找可用端口...", original_port);

    match find_available_port(host, original_port + 1, 100) {
        Ok(available_port) => {
            info!("找到可用端口: {}", available_port);
            config.server.port = available_port;
            let addr = format!("{}:{}", host, available_port).parse()?;
            Ok(addr)
        }
        Err(e) => Err(anyhow!("无法找到可用端口: {}", e)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = AppConfig::default();
        assert_eq!(config.server.host, "0.0.0.0");
        assert_eq!(config.server.port, 3000);
        assert_eq!(config.server.log_level, "info");
        assert_eq!(
            config.oauth.auth_url,
            "https://auth.augmentcode.com/authorize"
        );
        assert_eq!(config.oauth.client_id, "v");
        assert_eq!(config.oauth.state_expire_minutes, 30);
    }

    #[test]
    fn test_server_addr() {
        let config = AppConfig::default();
        assert_eq!(config.server_addr(), "0.0.0.0:3000");
    }

    #[test]
    fn test_is_port_available() {
        // 测试端口 0，系统会自动分配一个可用端口
        assert!(is_port_available("127.0.0.1", 0));

        // 测试一个已知被占用的端口（绑定后再测试）
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let addr = listener.local_addr().unwrap();
        let port = addr.port();

        // 端口现在被占用，应该返回 false
        assert!(!is_port_available("127.0.0.1", port));

        // 释放端口
        drop(listener);

        // 现在端口应该可用了
        assert!(is_port_available("127.0.0.1", port));
    }

    #[test]
    fn test_find_available_port() {
        // 从一个高端口开始查找
        let result = find_available_port("127.0.0.1", 65000, 10);
        assert!(result.is_ok());
        let port = result.unwrap();
        assert!(port >= 65000 && port < 65010);
    }
}
