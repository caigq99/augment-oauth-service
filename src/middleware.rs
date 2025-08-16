use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use tracing::error;

use crate::models::ErrorResponse;

/// 创建统一的错误响应
pub fn create_error_response(status: StatusCode, message: String) -> Response {
    let error_response = ErrorResponse::new(message);
    (status, Json(error_response)).into_response()
}

/// 创建内部服务器错误响应
pub fn internal_server_error(message: String) -> Response {
    error!("Internal server error: {}", message);
    create_error_response(StatusCode::INTERNAL_SERVER_ERROR, message)
}

/// 创建客户端错误响应
pub fn bad_request(message: String) -> Response {
    create_error_response(StatusCode::BAD_REQUEST, message)
}

/// 创建未找到错误响应
pub fn not_found(message: String) -> Response {
    create_error_response(StatusCode::NOT_FOUND, message)
}

/// 创建未授权错误响应
pub fn unauthorized(message: String) -> Response {
    create_error_response(StatusCode::UNAUTHORIZED, message)
}
