# FastAPI 會員登入系統

簡單的 FastAPI 應用程式，提供基本的會員登入功能。

## 安裝步驟

1. 安裝所需套件：
```bash
pip install -r requirements.txt
```

## 執行方式

### 使用 Docker（推薦）

```bash
# 使用 Docker Compose 啟動
docker-compose up -d

# 查看日誌
docker-compose logs -f

# 停止服務
docker-compose down
```

### 本地執行

```bash
python main.py
```

或使用 uvicorn：
```bash
uvicorn main:app --reload
```

伺服器將在 http://localhost:1234 啟動（Docker）或 http://localhost:8000（本地執行）

## API 文件

啟動後可訪問：
- Swagger UI: http://localhost:1234/docs（Docker）或 http://localhost:8000/docs（本地執行）
- ReDoc: http://localhost:1234/redoc（Docker）或 http://localhost:8000/redoc（本地執行）

## API 端點

### 1. 登入
- **POST** `/login`
- Body:
```json
{
  "username": "user@example.com",
  "password": "password123"
}
```
- 回傳: JWT token

### 2. 取得當前使用者資訊
- **GET** `/me`
- Header: `Authorization: Bearer <token>`
- 回傳: 使用者資訊

## 測試帳號

- 帳號: `user@example.com`
- 密碼: `password123`

## 測試

執行自動化測試：
```bash
python test_api.py
```

測試腳本會自動：
1. 啟動 FastAPI 服務器
2. 執行以下測試案例：
   - 訪問根路徑
   - 正確帳號密碼登入
   - 錯誤密碼登入（應被拒絕）
   - 不存在的帳號登入（應被拒絕）
   - 使用有效 Token 取得使用者資訊
   - 使用無效 Token（應被拒絕）
3. 自動關閉服務器

## 注意事項

- 這是示範程式碼，SECRET_KEY 應在正式環境中更換
- 目前使用記憶體儲存使用者資料，實際應用應使用資料庫
