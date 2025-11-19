# 測試根路徑
GET http://localhost:8000/
HTTP 200
[Asserts]
jsonpath "$.message" exists

# 測試成功登入
POST http://localhost:8000/login
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
token: jsonpath "$.access_token"

# 測試錯誤密碼登入
POST http://localhost:8000/login
Content-Type: application/json
{
  "username": "user@example.com",
  "password": "wrongpassword"
}
HTTP 401
[Asserts]
jsonpath "$.detail" exists

# 測試使用 Token 取得使用者資訊
GET http://localhost:8000/me
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.username" == "user@example.com"
jsonpath "$.full_name" exists

# 測試無效 Token
GET http://localhost:8000/me
Authorization: Bearer invalid_token_here
HTTP 401
