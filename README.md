# FastAPI 會員登入系統

簡單的 FastAPI 應用程式，提供基本的會員登入功能。

## 安裝步驟

1. 安裝所需套件：
```bash
pip install -r requirements.txt
```

## 執行方式

```bash
python main.py
```

或使用 uvicorn：
```bash
uvicorn main:app --reload
```

伺服器將在 http://localhost:8000 啟動

## API 文件

啟動後可訪問：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

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

### Python 測試 (pytest)

執行自動化測試：
```bash
pytest test_main.py -v
```

測試案例包含：
- 訪問根路徑
- 正確帳號密碼登入
- 錯誤密碼登入（應被拒絕）
- 不存在的帳號登入（應被拒絕）
- 使用有效 Token 取得使用者資訊
- 使用無效 Token（應被拒絕）

### Hurl API 測試

使用 Hurl 進行 HTTP API 測試：

1. 安裝 Hurl：
```bash
# macOS
brew install hurl

# Linux
curl --location --remote-name https://github.com/Orange-OpenSource/hurl/releases/download/4.3.0/hurl_4.3.0_amd64.deb
sudo dpkg -i hurl_4.3.0_amd64.deb
```

2. 啟動伺服器：
```bash
python main.py
```

3. 執行 Hurl 測試：
```bash
hurl --test api-tests.hurl
```

## CI/CD 流程

本專案已設定 GitHub Actions CI 流程，會在 Pull Request 時自動執行：

### 自動檢查項目

1. **程式碼品質檢查 (Code Quality Checks)**
   - Black 格式化檢查：確保程式碼符合 PEP 8 風格指南
   - Flake8 語法檢查：檢測 Python 語法錯誤和程式碼問題
   - Bandit 安全性掃描：檢查常見的安全漏洞

2. **相依套件漏洞檢查 (Dependency Vulnerability Check)**
   - pip-audit：掃描 requirements.txt 中的套件是否有已知安全漏洞

3. **自動化測試 (Run Tests)**
   - 執行所有測試案例
   - 生成測試覆蓋率報告

4. **Hurl API 測試 (Hurl API Tests)**
   - 使用 Hurl 執行 HTTP API 測試
   - 驗證 API 端點行為和回應

### CI 工作流程說明

當您建立或更新 Pull Request 時：
1. CI 會自動觸發並執行所有檢查
2. 檢查結果會顯示在 PR 頁面
3. CI 會自動在 PR 中留言，摘要所有檢查結果
4. 查看詳細記錄可點擊 Actions 頁籤

### 本地執行 CI 檢查

在提交 PR 前，您可以在本地執行相同的檢查：

```bash
# 安裝檢查工具
pip install black flake8 bandit pytest pytest-cov httpx pip-audit

# 格式化檢查
black --check .

# 語法檢查
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

# 安全性掃描
bandit -r . -f screen

# 相依套件漏洞檢查
pip-audit -r requirements.txt

# 執行測試
pytest -v --cov=.

# 執行 Hurl API 測試 (需要先啟動伺服器)
# 在一個終端機執行：python main.py
# 在另一個終端機執行：hurl --test api-tests.hurl
```

## 注意事項

- 這是示範程式碼，SECRET_KEY 應在正式環境中更換
- 目前使用記憶體儲存使用者資料，實際應用應使用資料庫
