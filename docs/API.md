# API 文档

Augment OAuth Service 提供了简洁的 RESTful API，实现 OAuth 2.0 PKCE 流程。

## 基础信息

- **Base URL**: `http://localhost:3000` (默认)
- **Content-Type**: `application/json`
- **字符编码**: UTF-8

## 统一响应格式

所有 API 都使用统一的 JSON 响应格式：

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

## API 端点

### 1. 健康检查

检查服务运行状态。

**请求**
```
GET /health
```

**响应示例**
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

**状态码**
- `200`: 服务正常运行

---

### 2. 获取授权链接

生成 OAuth 授权链接，启动授权流程。

**请求**
```
GET /api/auth-url?user_id={user_id}
```

**查询参数**
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `user_id` | string | 否 | 用户标识符，用于日志记录 |

**响应示例**
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

**响应字段说明**
- `authorize_url`: 完整的授权链接，用户需要访问此链接进行授权
- `state`: 状态参数，用于防止 CSRF 攻击，完成授权时需要提供

**状态码**
- `200`: 成功生成授权链接
- `500`: 服务器内部错误

**使用流程**
1. 调用此 API 获取授权链接和 state
2. 将用户重定向到 `authorize_url`
3. 用户完成授权后，会重定向回您的回调地址，并携带 `code` 和 `state` 参数
4. 使用获得的 `code` 和 `state` 调用完成授权 API

---

### 3. 完成授权

使用授权码完成 OAuth 流程并获取访问令牌。

**请求**
```
POST /api/complete-auth
Content-Type: application/json
```

**请求体**
```json
{
  "code": "authorization_code_from_callback",
  "state": "state_value_from_step1",
  "tenant_url": "https://your-tenant.augmentcode.com/"
}
```

**请求字段说明**
| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `code` | string | 是 | 从授权回调中获得的授权码 |
| `state` | string | 是 | 从获取授权链接 API 中获得的状态值 |
| `tenant_url` | string | 是 | 租户 URL，用于 token 交换 |

**成功响应示例**
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

**响应字段说明**
- `status`: 授权状态，成功时为 "success"
- `token`: 访问令牌，用于后续 API 调用
- `tenant_url`: 租户 URL
- `token_info.id`: 令牌唯一标识符
- `token_info.created_at`: 令牌创建时间

**错误响应示例**
```json
{
  "success": false,
  "data": {},
  "message": "无效的请求数据: code, state, tenant_url 都是必需的"
}
```

**状态码**
- `200`: 授权成功
- `400`: 请求参数错误
- `500`: 服务器内部错误

**常见错误**
- `无效的请求数据`: 缺少必需参数
- `未找到OAuth状态`: state 参数无效或已过期
- `OAuth状态已过期`: state 超过 30 分钟有效期
- `Token交换失败`: 与授权服务器通信失败

## 完整的 OAuth 流程示例

### 1. 获取授权链接

```bash
curl -X GET "http://localhost:3000/api/auth-url?user_id=test_user"
```

**响应:**
```json
{
  "success": true,
  "data": {
    "authorize_url": "https://auth.augmentcode.com/authorize?response_type=code&code_challenge=xxx&client_id=v&state=abc123&prompt=login",
    "state": "abc123"
  },
  "message": "授权链接生成成功"
}
```

### 2. 用户授权

用户访问 `authorize_url` 进行授权，完成后重定向到您的回调地址：
```
https://your-callback-url.com/callback?code=received_code&state=abc123
```

### 3. 完成授权

```bash
curl -X POST "http://localhost:3000/api/complete-auth" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "received_code",
    "state": "abc123",
    "tenant_url": "https://your-tenant.augmentcode.com/"
  }'
```

**成功响应:**
```json
{
  "success": true,
  "data": {
    "status": "success",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tenant_url": "https://your-tenant.augmentcode.com/",
    "token_info": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "created_at": "2025-01-01T12:00:00Z"
    }
  },
  "message": "OAuth授权完成成功"
}
```

## 错误处理

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 404 | 端点不存在 |
| 500 | 服务器内部错误 |

### 错误类型

#### 客户端错误 (4xx)

**400 Bad Request**
```json
{
  "success": false,
  "data": {},
  "message": "无效的请求数据: code, state, tenant_url 都是必需的"
}
```

**404 Not Found**
```json
{
  "success": false,
  "data": {},
  "message": "请求的资源不存在"
}
```

#### 服务器错误 (5xx)

**500 Internal Server Error**
```json
{
  "success": false,
  "data": {},
  "message": "Token交换失败: 网络连接超时"
}
```

## 安全考虑

### PKCE 流程

本服务实现了 OAuth 2.0 PKCE (Proof Key for Code Exchange) 流程：

1. **Code Verifier**: 随机生成的字符串
2. **Code Challenge**: Code Verifier 的 SHA256 哈希值
3. **State**: 防止 CSRF 攻击的随机状态值

### 状态管理

- OAuth 状态在内存中存储，服务重启后会清空
- 状态有效期为 30 分钟，过期后自动清理
- 每个状态只能使用一次，使用后立即删除

### 安全建议

1. **使用 HTTPS**: 生产环境中务必使用 HTTPS
2. **验证回调 URL**: 确保回调 URL 的合法性
3. **Token 安全**: 妥善保存访问令牌，避免泄露
4. **状态验证**: 严格验证 state 参数

## 限制和约束

- **并发限制**: 无特殊限制，支持高并发访问
- **状态存储**: 内存存储，服务重启后状态丢失
- **Token 有效期**: 由授权服务器决定
- **请求大小**: 请求体大小限制为 1MB

## 监控和日志

### 请求日志

服务会记录所有 API 请求的详细信息：

```
INFO augment_oauth_service::handlers: 收到获取授权链接请求, user_id: Some("test_user")
INFO augment_oauth_service::handlers: 授权链接生成成功: https://auth.augmentcode.com/authorize?...
INFO augment_oauth_service::handlers: 收到完成授权请求, code: present, state: abc123, tenant_url: https://test.com/
INFO augment_oauth_service::handlers: OAuth授权完成成功, token_id: 550e8400-e29b-41d4-a716-446655440000
```

### 健康检查

定期调用健康检查端点监控服务状态：

```bash
# 每 30 秒检查一次
watch -n 30 'curl -s http://localhost:3000/health | jq'
```
