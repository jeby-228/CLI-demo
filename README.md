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

### Hurl 測試

[Hurl](https://hurl.dev/) 是一個命令行工具，用於運行和測試 HTTP 請求。詳細的 Hurl 使用說明請參考 [HURL_GUIDE.md](HURL_GUIDE.md)。

#### 安裝 Hurl

在 Ubuntu/Debian 系統上：
```bash
curl --location --remote-name https://github.com/Orange-OpenSource/hurl/releases/download/4.3.0/hurl_4.3.0_amd64.deb
sudo dpkg -i hurl_4.3.0_amd64.deb
```

或查看 [Hurl 官方安裝文件](https://hurl.dev/docs/installation.html) 了解其他平台。

#### 執行 Hurl 測試

**本地測試（port 8000）：**
```bash
# 使用便利腳本
./run_hurl_tests.sh

# 或手動執行
python main.py &  # 啟動服務器
hurl --test --verbose test_api.hurl
```

**Docker 測試（port 1234）：**
```bash
# 使用便利腳本
./run_hurl_tests.sh docker

# 或手動執行
docker-compose up -d  # 啟動 Docker 容器
hurl --test --verbose test_api_docker.hurl
```

#### Hurl 測試內容

測試文件包含以下測試案例：
- ✓ 訪問根路徑
- ✓ 使用正確的帳號密碼登入
- ✓ 使用錯誤的密碼登入（應被拒絕）
- ✓ 使用不存在的帳號登入（應被拒絕）
- ✓ 使用有效 Token 取得使用者資訊
- ✓ 使用無效 Token（應被拒絕）
- ✓ 不提供 Token（應被拒絕）

## CI/CD 與部署

本專案已設定 GitHub Actions 自動化部署到 Google Cloud Platform (GCP) Cloud Run。

### 功能特點

- ✅ 自動化測試（Python + Hurl）
- ✅ Docker 映像建構
- ✅ 推送到 Google Artifact Registry
- ✅ 自動部署到 Cloud Run
- ✅ Pull Request 自動測試

### 部署到 GCP

詳細的 GCP CI/CD 設定指南，請參閱 [GCP_DEPLOYMENT.md](GCP_DEPLOYMENT.md)。

快速開始：

1. **在 GCP 建立專案並啟用 API**
2. **建立服務帳號並取得金鑰**
3. **在 GitHub 設定 Secrets**：
   - `GCP_PROJECT_ID`: 你的 GCP 專案 ID
   - `GCP_SA_KEY`: 服務帳號的 JSON 金鑰
   - `SECRET_KEY`: JWT 密鑰
4. **推送到 main 分支即可自動部署**

### 工作流程

- **Pull Request**: 自動執行所有測試
- **Push to main**: 執行測試 → 建構 Docker 映像 → 部署到 Cloud Run

## 注意事項

- 這是示範程式碼，SECRET_KEY 應在正式環境中更換
- 目前使用記憶體儲存使用者資料，實際應用應使用資料庫
