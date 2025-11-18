# GCP Cloud Run 部署指南

本文件說明如何設置 CI/CD 管道，將 FastAPI 應用程式自動部署到 Google Cloud Platform (GCP) 的 Cloud Run。

## 前置需求

1. GCP 帳號和專案
2. GitHub 帳號和存儲庫
3. 已啟用的 GCP API

## GCP 設定步驟

### 1. 建立 GCP 專案

如果還沒有專案，請在 [GCP Console](https://console.cloud.google.com/) 建立一個新專案。

### 2. 啟用必要的 API

在 GCP Console 中啟用以下 API：

```bash
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

或者在 GCP Console 中手動啟用：
- Cloud Build API
- Cloud Run API
- Artifact Registry API
- Container Registry API

### 3. 建立 Artifact Registry 儲存庫

建立 Docker 儲存庫來存放容器映像：

```bash
gcloud artifacts repositories create fastapi-login-system \
    --repository-format=docker \
    --location=asia-east1 \
    --description="FastAPI login system Docker images"
```

### 4. 建立服務帳號

建立一個服務帳號用於 GitHub Actions：

```bash
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions Service Account"
```

### 5. 授予必要的權限

給予服務帳號所需的權限：

```bash
# 取得專案 ID
PROJECT_ID=$(gcloud config get-value project)

# 授予權限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"
```

### 6. 建立服務帳號金鑰

產生 JSON 金鑰檔案：

```bash
gcloud iam service-accounts keys create key.json \
    --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com
```

這會在當前目錄建立 `key.json` 檔案。**請妥善保管此檔案，不要提交到 Git 儲存庫！**

## GitHub 設定步驟

### 1. 設定 GitHub Secrets

在你的 GitHub 儲存庫中，前往 `Settings` > `Secrets and variables` > `Actions`，新增以下 secrets：

#### 必要的 Secrets：

1. **GCP_PROJECT_ID**
   - 值：你的 GCP 專案 ID
   - 取得方式：`gcloud config get-value project`

2. **GCP_SA_KEY**
   - 值：服務帳號 JSON 金鑰的完整內容
   - 將 `key.json` 檔案的完整內容複製貼上（包含 `{` 和 `}`）

3. **SECRET_KEY**
   - 值：應用程式的密鑰（用於 JWT token）
   - 建議使用強隨機字串，例如：
   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

### 2. 調整工作流程設定（可選）

如需調整部署區域或服務名稱，請編輯 `.github/workflows/gcp-deploy.yml`：

```yaml
env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  REGION: asia-east1  # 可改為其他區域，如 us-central1
  SERVICE_NAME: fastapi-login-system  # 可改為自訂名稱
```

## 工作流程說明

### 觸發條件

CI/CD 管道會在以下情況下觸發：

1. **Pull Request**: 推送到 `main` 分支的 PR 會觸發測試
2. **Push to main**: 推送到 `main` 分支會觸發完整的測試、建構和部署
3. **Manual trigger**: 可以在 GitHub Actions 頁面手動觸發

### 工作流程階段

#### 1. 測試階段 (Test)

- 設定 Python 環境
- 安裝相依套件
- 執行 Python 測試
- 安裝和執行 Hurl 測試

#### 2. 建構和部署階段 (Build and Deploy)

只在推送到 `main` 分支時執行：

1. **認證**: 使用服務帳號金鑰向 GCP 認證
2. **建構**: 建立 Docker 映像
3. **推送**: 推送映像到 Artifact Registry
4. **部署**: 部署到 Cloud Run
5. **驗證**: 測試已部署的服務

## 部署後

### 取得服務 URL

部署成功後，可以透過以下方式取得服務 URL：

```bash
gcloud run services describe fastapi-login-system \
    --region=asia-east1 \
    --format='value(status.url)'
```

或在 [Cloud Run Console](https://console.cloud.google.com/run) 查看。

### 測試部署的服務

```bash
# 取得 URL
SERVICE_URL=$(gcloud run services describe fastapi-login-system \
    --region=asia-east1 \
    --format='value(status.url)')

# 測試根路徑
curl $SERVICE_URL

# 測試登入
curl -X POST $SERVICE_URL/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user@example.com","password":"password123"}'
```

### 查看日誌

```bash
gcloud run services logs read fastapi-login-system \
    --region=asia-east1 \
    --limit=50
```

或在 [Cloud Logging](https://console.cloud.google.com/logs) 查看。

## 成本考量

Cloud Run 採用隨用隨付模式：

- **免費額度**: 每月 200 萬次請求、36 萬 vCPU 秒、100 萬 GB 秒
- **最小實例數設為 0**: 沒有流量時不收費
- **自動擴展**: 根據流量自動調整實例數

更多資訊請參考 [Cloud Run 定價](https://cloud.google.com/run/pricing)。

## 自訂配置

### 調整 Cloud Run 設定

可以在 `.github/workflows/gcp-deploy.yml` 中調整以下參數：

```yaml
--memory 512Mi          # 記憶體配置 (128Mi 至 32Gi)
--cpu 1                 # CPU 數量 (0.08 至 8)
--min-instances 0       # 最小實例數
--max-instances 10      # 最大實例數
--timeout 300           # 請求逾時時間（秒）
```

### 環境變數

在 GitHub Secrets 中新增環境變數，然後在工作流程中設定：

```yaml
--set-env-vars KEY1=value1,KEY2=value2
```

或使用 secrets：

```yaml
--set-env-vars SECRET_KEY=${{ secrets.SECRET_KEY }},DATABASE_URL=${{ secrets.DATABASE_URL }}
```

## 安全性建議

1. **定期輪換服務帳號金鑰**: 建議每 90 天輪換一次
2. **最小權限原則**: 只授予服務帳號所需的最小權限
3. **使用 Secrets 管理敏感資訊**: 絕不將密鑰硬編碼在程式碼中
4. **啟用 Cloud Run 認證**: 對於生產環境，考慮啟用 Cloud Run IAM 認證

## 疑難排解

### 常見問題

1. **部署失敗：權限不足**
   - 檢查服務帳號是否有足夠的權限
   - 確認 API 已啟用

2. **Docker 映像推送失敗**
   - 確認 Artifact Registry 儲存庫已建立
   - 檢查服務帳號是否有寫入權限

3. **服務無法存取**
   - 檢查 `--allow-unauthenticated` 旗標是否設定
   - 確認防火牆規則

4. **應用程式錯誤**
   - 查看 Cloud Run 日誌
   - 檢查環境變數是否正確設定

### 查看日誌

```bash
# Cloud Run 日誌
gcloud run services logs read fastapi-login-system --region=asia-east1

# GitHub Actions 日誌
# 在 GitHub 儲存庫的 Actions 頁籤查看
```

## 進階功能

### 多環境部署

可以建立多個工作流程檔案用於不同環境：

- `.github/workflows/deploy-dev.yml` - 開發環境
- `.github/workflows/deploy-staging.yml` - 測試環境
- `.github/workflows/gcp-deploy.yml` - 生產環境

### 使用 Workload Identity Federation

為了更安全的認證，可以使用 Workload Identity Federation 取代服務帳號金鑰：

參考：[Workload Identity Federation for GitHub Actions](https://github.com/google-github-actions/auth#workload-identity-federation)

### 藍綠部署

Cloud Run 支援流量分割，可實現藍綠部署：

```bash
# 部署新版本但不切換流量
gcloud run deploy $SERVICE_NAME --no-traffic --tag=blue

# 驗證後切換流量
gcloud run services update-traffic $SERVICE_NAME --to-latest
```

## 參考資源

- [Cloud Run 文件](https://cloud.google.com/run/docs)
- [GitHub Actions 文件](https://docs.github.com/actions)
- [Artifact Registry 文件](https://cloud.google.com/artifact-registry/docs)
- [FastAPI 部署指南](https://fastapi.tiangolo.com/deployment/)

## 支援

如有問題，請在 GitHub Issues 中提出。
