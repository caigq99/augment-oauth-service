use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use base64::{Engine as _, engine::general_purpose};
use serde_json::Value;

/// 统一API响应格式
#[derive(Debug, Serialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: T,
    pub message: String,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T) -> Self {
        Self {
            success: true,
            data,
            message: "操作成功".to_string(),
        }
    }

    pub fn success_with_message(data: T, message: String) -> Self {
        Self {
            success: true,
            data,
            message,
        }
    }
}

/// 错误响应（data为空对象）
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub success: bool,
    pub data: Value,
    pub message: String,
}

impl ErrorResponse {
    pub fn new(message: String) -> Self {
        Self {
            success: false,
            data: Value::Object(serde_json::Map::new()),
            message,
        }
    }
}

/// OAuth状态信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OAuthState {
    pub code_verifier: String,
    pub code_challenge: String,
    pub state: String,
    pub creation_time: DateTime<Utc>,
}

/// 获取授权链接的响应数据
#[derive(Debug, Serialize)]
pub struct AuthUrlData {
    pub authorize_url: String,
    pub state: String,
}

/// 完成授权的请求
#[derive(Debug, Deserialize)]
pub struct CompleteAuthRequest {
    pub code: String,
    pub state: String,
    pub tenant_url: String,
}

/// 完成授权的响应数据
#[derive(Debug, Serialize)]
pub struct CompleteAuthData {
    pub status: String,
    pub token: String,
    pub tenant_url: String,
    pub token_info: TokenInfo,
}

/// Token信息
#[derive(Debug, Serialize)]
pub struct TokenInfo {
    pub id: String,
    pub created_at: DateTime<Utc>,
}



/// Token交换请求
#[derive(Debug, Serialize)]
pub struct TokenExchangeRequest {
    pub grant_type: String,
    pub client_id: String,
    pub code_verifier: String,
    pub redirect_uri: String,
    pub code: String,
}

/// Token交换响应
#[derive(Debug, Deserialize)]
pub struct TokenExchangeResponse {
    pub access_token: String,
    pub token_type: Option<String>,
    pub expires_in: Option<u64>,
    pub refresh_token: Option<String>,
}

impl OAuthState {
    pub fn new() -> Self {
        let code_verifier = generate_code_verifier();
        let code_challenge = generate_code_challenge(&code_verifier);
        let state = generate_state();

        Self {
            code_verifier,
            code_challenge,
            state,
            creation_time: Utc::now(),
        }
    }

    /// 检查状态是否过期（30分钟）
    pub fn is_expired(&self) -> bool {
        let now = Utc::now();
        let duration = now.signed_duration_since(self.creation_time);
        duration.num_minutes() > 30
    }
}

/// 生成code_verifier (PKCE)
fn generate_code_verifier() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    let bytes: Vec<u8> = (0..32).map(|_| rng.gen()).collect();
    general_purpose::URL_SAFE_NO_PAD.encode(bytes)
}

/// 生成code_challenge (PKCE)
fn generate_code_challenge(code_verifier: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(code_verifier.as_bytes());
    let hash = hasher.finalize();
    general_purpose::URL_SAFE_NO_PAD.encode(hash)
}

/// 生成state参数
fn generate_state() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    let bytes: Vec<u8> = (0..8).map(|_| rng.gen()).collect();
    general_purpose::URL_SAFE_NO_PAD.encode(bytes)
}
