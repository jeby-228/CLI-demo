# FastAPI 會員登入系統 - Hurl 測試 (Docker 環境)
# 這個測試文件用於測試在 Docker 容器中運行的 API (port 1234)

# ============================================
# 測試 1: 訪問根路徑
# ============================================
GET http://localhost:1234/

HTTP 200
[Asserts]
jsonpath "$.message" == "歡迎使用會員登入系統 API"


# ============================================
# 測試 2: 使用正確的帳號密碼登入
# ============================================
POST http://localhost:1234/login
Content-Type: application/json
{
  "username": "user@example.com",
  "password": "password123"
}

HTTP 200
[Asserts]
jsonpath "$.access_token" exists
jsonpath "$.token_type" == "bearer"
[Captures]
access_token: jsonpath "$.access_token"


# ============================================
# 測試 3: 使用錯誤的密碼登入
# ============================================
POST http://localhost:1234/login
Content-Type: application/json
{
  "username": "user@example.com",
  "password": "wrongpassword"
}

HTTP 401
[Asserts]
jsonpath "$.detail" == "帳號或密碼錯誤"


# ============================================
# 測試 4: 使用不存在的帳號登入
# ============================================
POST http://localhost:1234/login
Content-Type: application/json
{
  "username": "nonexistent@example.com",
  "password": "password123"
}

HTTP 401
[Asserts]
jsonpath "$.detail" == "帳號或密碼錯誤"


# ============================================
# 測試 5: 使用有效 Token 取得使用者資訊
# ============================================
GET http://localhost:1234/me
Authorization: Bearer {{access_token}}

HTTP 200
[Asserts]
jsonpath "$.username" == "user@example.com"
jsonpath "$.full_name" == "測試使用者"


# ============================================
# 測試 6: 使用無效的 Token
# ============================================
GET http://localhost:1234/me
Authorization: Bearer invalid_token_here

HTTP 500


# ============================================
# 測試 7: 不提供 Token
# ============================================
GET http://localhost:1234/me

HTTP 403
[Asserts]
jsonpath "$.detail" == "Not authenticated"
