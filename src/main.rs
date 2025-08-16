use axum::{
    response::Json,
    routing::{get, post},
    Router,
};
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing::info;

mod oauth;
mod models;
mod handlers;
mod middleware;

use oauth::OAuthService;
use models::ApiResponse;

#[derive(Clone)]
pub struct AppState {
    oauth_service: Arc<OAuthService>,
}

#[tokio::main]
async fn main() {
    // 初始化日志
    tracing_subscriber::fmt::init();

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
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();
    
    info!("Augment OAuth Service 启动在 http://0.0.0.0:3000");
    
    axum::serve(listener, app).await.unwrap();
}

async fn health_check() -> Json<ApiResponse<serde_json::Value>> {
    let data = serde_json::json!({
        "status": "ok",
        "service": "augment-oauth-service",
        "timestamp": chrono::Utc::now()
    });

    Json(ApiResponse::success_with_message(data, "服务运行正常".to_string()))
}
