use crate::models::{OAuthState, TokenExchangeRequest, TokenExchangeResponse};
use anyhow::{Result, anyhow};
use dashmap::DashMap;
use std::sync::Arc;
use tracing::{info, error};
use url::Url;

/// OAuth服务
pub struct OAuthService {
    /// 存储OAuth状态的内存映射 (state -> OAuthState)
    oauth_states: Arc<DashMap<String, OAuthState>>,
}

impl OAuthService {
    pub fn new() -> Self {
        Self {
            oauth_states: Arc::new(DashMap::new()),
        }
    }

    /// 生成授权URL
    pub fn generate_auth_url(&self) -> Result<(String, String)> {
        // 创建OAuth状态
        let oauth_state = OAuthState::new();
        let state = oauth_state.state.clone();

        // 构建授权URL参数
        let mut url = Url::parse("https://auth.augmentcode.com/authorize")?;
        url.query_pairs_mut()
            .append_pair("response_type", "code")
            .append_pair("code_challenge", &oauth_state.code_challenge)
            .append_pair("client_id", "v")
            .append_pair("state", &oauth_state.state)
            .append_pair("prompt", "login");

        let auth_url = url.to_string();

        // 保存OAuth状态
        self.oauth_states.insert(state.clone(), oauth_state);

        info!("生成授权链接: {}", auth_url);

        Ok((auth_url, state))
    }

    /// 验证state并获取OAuth状态
    pub fn get_oauth_state(&self, state: &str) -> Result<OAuthState> {
        // 获取OAuth状态
        let oauth_state = self.oauth_states
            .get(state)
            .ok_or_else(|| anyhow!("未找到OAuth状态，请重新获取授权链接"))?
            .clone();

        // 检查是否过期
        if oauth_state.is_expired() {
            self.oauth_states.remove(state);
            return Err(anyhow!("OAuth状态已过期，请重新获取授权链接"));
        }

        Ok(oauth_state)
    }

    /// 清除OAuth状态
    pub fn clear_oauth_state(&self, state: &str) {
        self.oauth_states.remove(state);
    }

    /// 使用授权码交换访问令牌
    pub async fn exchange_token(
        &self,
        tenant_url: &str,
        code_verifier: &str,
        code: &str,
    ) -> Result<String> {
        // 构建token端点URL
        let token_url = if tenant_url.ends_with('/') {
            format!("{}token", tenant_url)
        } else {
            format!("{}/token", tenant_url)
        };

        // 构建请求数据
        let request_data = TokenExchangeRequest {
            grant_type: "authorization_code".to_string(),
            client_id: "v".to_string(),
            code_verifier: code_verifier.to_string(),
            redirect_uri: "".to_string(),
            code: code.to_string(),
        };

        info!("请求token交换: {}", token_url);

        // 发送HTTP请求
        let client = reqwest::Client::new();
        let response = client
            .post(&token_url)
            .header("Content-Type", "application/json")
            .json(&request_data)
            .send()
            .await?;

        // 检查响应状态
        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            error!("Token交换失败: {} - {}", status, error_text);
            return Err(anyhow!("请求令牌失败: {} {}", status, error_text));
        }

        // 解析响应
        let token_response: TokenExchangeResponse = response.json().await?;

        info!("Token交换成功");

        Ok(token_response.access_token)
    }

    /// 清理过期的OAuth状态
    pub fn cleanup_expired_states(&self) {
        let mut expired_keys = Vec::new();

        // 收集过期的key
        for entry in self.oauth_states.iter() {
            if entry.value().is_expired() {
                expired_keys.push(entry.key().clone());
            }
        }

        // 删除过期的状态
        for key in expired_keys {
            self.oauth_states.remove(&key);
        }

        if !self.oauth_states.is_empty() {
            info!("清理过期OAuth状态，当前活跃状态数: {}", self.oauth_states.len());
        }
    }

    /// 获取当前活跃的OAuth状态数量
    pub fn active_states_count(&self) -> usize {
        self.oauth_states.len()
    }
}

impl Default for OAuthService {
    fn default() -> Self {
        Self::new()
    }
}
