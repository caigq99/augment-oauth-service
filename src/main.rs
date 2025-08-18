use axum::{
    response::Json,
    routing::{get, post},
    Router,
};
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing::{error, info};

mod config;
mod handlers;
mod middleware;
mod models;
mod oauth;

use config::{get_available_server_addr, AppConfig};
use models::ApiResponse;
use oauth::OAuthService;

#[derive(Clone)]
pub struct AppState {
    oauth_service: Arc<OAuthService>,
}

#[tokio::main]
async fn main() {
    // 加载配置
    let mut config = match AppConfig::load() {
        Ok(config) => config,
        Err(e) => {
            eprintln!("配置加载失败: {}", e);
            std::process::exit(1);
        }
    };

    // 初始化日志
    tracing_subscriber::fmt::init();

    info!("Augment OAuth Service 正在启动...");
    info!(
        "配置信息: 主机={}, 端口={}",
        config.server.host, config.server.port
    );

    // 获取可用的服务器地址
    let server_addr = match get_available_server_addr(&mut config).await {
        Ok(addr) => addr,
        Err(e) => {
            error!("无法获取可用的服务器地址: {}", e);
            std::process::exit(1);
        }
    };

    // 创建OAuth服务
    let oauth_service = Arc::new(OAuthService::new());

    // 创建应用状态
    let app_state = AppState { oauth_service };

    // 创建路由
    let app = Router::new()
        .route("/api/auth-url", get(handlers::get_auth_url))
        .route("/api/complete-auth", post(handlers::complete_auth))
        .route("/health", get(health_check))
        .layer(CorsLayer::permissive())
        .with_state(app_state);

    // 启动服务器
    let listener = match tokio::net::TcpListener::bind(server_addr).await {
        Ok(listener) => listener,
        Err(e) => {
            error!("无法绑定到地址 {}: {}", server_addr, e);
            std::process::exit(1);
        }
    };

    info!("Augment OAuth Service 启动成功！");
    info!("服务地址: http://{}", server_addr);
    info!("健康检查: http://{}/health", server_addr);
    info!("获取授权链接: http://{}/api/auth-url", server_addr);
    info!("完成授权: http://{}/api/complete-auth", server_addr);

    if let Err(e) = axum::serve(listener, app).await {
        error!("服务器运行错误: {}", e);
        std::process::exit(1);
    }
}

async fn health_check() -> Json<ApiResponse<serde_json::Value>> {
    let data = serde_json::json!({
        "status": "ok",
        "service": "augment-oauth-service",
        "timestamp": chrono::Utc::now()
    });

    Json(ApiResponse::success_with_message(
        data,
        "服务运行正常".to_string(),
    ))
}
