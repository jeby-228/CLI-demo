# Hurl 測試說明

## 什麼是 Hurl？

[Hurl](https://hurl.dev/) 是一個命令行工具，用於運行和測試 HTTP 請求。它使用簡潔的純文本格式來定義 HTTP 請求和預期的響應，非常適合 API 測試和自動化。

## Hurl 的優勢

1. **純文本格式**：測試文件易讀易寫，可以用任何文本編輯器編輯
2. **內建斷言**：支持多種斷言類型，包括 HTTP 狀態碼、JSON 路徑、響應頭等
3. **變量捕獲**：可以從一個請求的響應中提取值，並在後續請求中使用
4. **無需編程**：不需要編寫代碼，適合非程序員使用
5. **CI/CD 友好**：可以輕松集成到持續集成/持續交付管道中

## 測試文件結構

### 基本請求

```hurl
GET http://localhost:8000/
```

### 帶斷言的請求

```hurl
GET http://localhost:8000/

HTTP 200
[Asserts]
jsonpath "$.message" == "歡迎使用會員登入系統 API"
```

### POST 請求與 JSON 數據

```hurl
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
```

### 捕獲變量

```hurl
POST http://localhost:8000/login
Content-Type: application/json
{
  "username": "user@example.com",
  "password": "password123"
}

HTTP 200
[Captures]
access_token: jsonpath "$.access_token"
```

### 使用變量

```hurl
GET http://localhost:8000/me
Authorization: Bearer {{access_token}}

HTTP 200
```

## 運行測試

### 基本運行

```bash
hurl test_api.hurl
```

### 測試模式（顯示測試結果）

```bash
hurl --test test_api.hurl
```

### 詳細模式（顯示所有請求和響應）

```bash
hurl --test --verbose test_api.hurl
```

### 生成 HTML 報告

```bash
hurl --test --report-html report test_api.hurl
```

## 本專案的測試文件

### test_api.hurl
本地環境測試文件（port 8000），包含以下測試案例：

1. **根路徑訪問**：測試 API 是否正常運行
2. **成功登入**：使用正確的帳號密碼登入，獲取 JWT token
3. **錯誤密碼**：驗證系統正確拒絕錯誤密碼
4. **不存在的帳號**：驗證系統正確拒絕不存在的帳號
5. **使用有效 Token**：使用從登入獲得的 token 訪問受保護的端點
6. **使用無效 Token**：驗證系統正確拒絕無效的 token
7. **不提供 Token**：驗證系統正確拒絕未認證的請求

### test_api_docker.hurl
Docker 環境測試文件（port 1234），測試案例與 test_api.hurl 相同，但使用不同的端口。

## 便利腳本

`run_hurl_tests.sh` 腳本提供了方便的測試執行方式：

### 本地測試
```bash
./run_hurl_tests.sh
```

### Docker 測試
```bash
./run_hurl_tests.sh docker
```

腳本會自動：
- 檢查 Hurl 是否已安裝
- 檢查服務器是否運行，如未運行則自動啟動
- 執行 Hurl 測試
- 顯示彩色輸出結果
- 測試完成後自動清理

## 更多資源

- [Hurl 官方文檔](https://hurl.dev/docs/)
- [Hurl GitHub 倉庫](https://github.com/Orange-OpenSource/hurl)
- [Hurl 安裝指南](https://hurl.dev/docs/installation.html)
- [Hurl 語法參考](https://hurl.dev/docs/syntax-reference.html)
