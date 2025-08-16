use axum::{
    extract::{Query, State},
    response::{IntoResponse, Json, Response},
};
use serde::Deserialize;
use tracing::info;
use uuid::Uuid;
use chrono::Utc;

use crate::{
    models::{ApiResponse, AuthUrlData, CompleteAuthRequest, CompleteAuthData, TokenInfo},
    middleware::{bad_request, internal_server_error},
    AppState,
};

/// 获取授权链接的查询参数
#[derive(Debug, Deserialize)]
pub struct AuthUrlQuery {
    pub user_id: Option<String>,
}

/// 获取OAuth授权链接
pub async fn get_auth_url(
    Query(query): Query<AuthUrlQuery>,
    State(state): State<AppState>,
) -> Response {
    info!("收到获取授权链接请求, user_id: {:?}", query.user_id);

    match state.oauth_service.generate_auth_url() {
        Ok((auth_url, state_param)) => {
            info!("授权链接生成成功: {}", auth_url);

            let data = AuthUrlData {
                authorize_url: auth_url,
                state: state_param,
            };

            Json(ApiResponse::success_with_message(data, "授权链接生成成功".to_string())).into_response()
        }
        Err(e) => {
            internal_server_error(format!("获取授权链接失败: {}", e))
        }
    }
}

/// 完成OAuth授权，获取访问令牌
pub async fn complete_auth(
    State(state): State<AppState>,
    Json(request): Json<CompleteAuthRequest>,
) -> Response {
    info!(
        "收到完成授权请求, code: {}, state: {}, tenant_url: {}",
        if request.code.is_empty() { "empty" } else { "present" },
        request.state,
        request.tenant_url
    );

    // 验证必需参数
    if request.code.is_empty() || request.state.is_empty() || request.tenant_url.is_empty() {
        return bad_request("无效的请求数据: code, state, tenant_url 都是必需的".to_string());
    }

    // 获取OAuth状态
    let oauth_state = match state.oauth_service.get_oauth_state(&request.state) {
        Ok(state) => state,
        Err(e) => {
            return bad_request(e.to_string());
        }
    };

    // 使用授权码交换访问令牌
    let access_token = match state
        .oauth_service
        .exchange_token(&request.tenant_url, &oauth_state.code_verifier, &request.code)
        .await
    {
        Ok(token) => token,
        Err(e) => {
            return internal_server_error(format!("Token交换失败: {}", e));
        }
    };

    // 清除已使用的OAuth状态
    state.oauth_service.clear_oauth_state(&request.state);

    // 生成token信息
    let token_info = TokenInfo {
        id: Uuid::new_v4().to_string(),
        created_at: Utc::now(),
    };

    info!("OAuth授权完成成功, token_id: {}", token_info.id);

    let data = CompleteAuthData {
        status: "success".to_string(),
        token: access_token,
        tenant_url: request.tenant_url,
        token_info,
    };

    Json(ApiResponse::success_with_message(data, "OAuth授权完成成功".to_string())).into_response()
}
