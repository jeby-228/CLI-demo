# GCP 部署快速參考

此文件提供常用的 GCP 部署命令，供快速參考使用。

## 前置作業

```bash
# 設定預設專案
gcloud config set project YOUR_PROJECT_ID

# 設定預設區域
gcloud config set run/region asia-east1
```

## 手動部署

### 使用 gcloud 直接部署

```bash
# 一鍵部署（適合測試）
gcloud run deploy fastapi-login-system \
  --source . \
  --region asia-east1 \
  --allow-unauthenticated \
  --port 1234
```

### 使用 Docker 部署

```bash
# 1. 建構映像
docker build -t asia-east1-docker.pkg.dev/YOUR_PROJECT_ID/fastapi-login-system/fastapi-login-system:latest .

# 2. 設定 Docker 認證
gcloud auth configure-docker asia-east1-docker.pkg.dev

# 3. 推送映像
docker push asia-east1-docker.pkg.dev/YOUR_PROJECT_ID/fastapi-login-system/fastapi-login-system:latest

# 4. 部署到 Cloud Run
gcloud run deploy fastapi-login-system \
  --image asia-east1-docker.pkg.dev/YOUR_PROJECT_ID/fastapi-login-system/fastapi-login-system:latest \
  --region asia-east1 \
  --allow-unauthenticated \
  --port 1234
```

### 使用 Cloud Build 部署

```bash
# 使用 cloudbuild.yaml 配置檔案部署
gcloud builds submit --config=cloudbuild.yaml
```

## 管理服務

### 查看服務資訊

```bash
# 列出所有 Cloud Run 服務
gcloud run services list

# 查看特定服務詳情
gcloud run services describe fastapi-login-system \
  --region asia-east1

# 取得服務 URL
gcloud run services describe fastapi-login-system \
  --region asia-east1 \
  --format='value(status.url)'
```

### 查看日誌

```bash
# 即時查看日誌
gcloud run services logs tail fastapi-login-system \
  --region asia-east1

# 查看最近的日誌
gcloud run services logs read fastapi-login-system \
  --region asia-east1 \
  --limit=100

# 查看特定時間範圍的日誌
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=fastapi-login-system" \
  --limit=50 \
  --format=json
```

### 更新服務配置

```bash
# 更新環境變數
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --set-env-vars SECRET_KEY=new-secret-key

# 更新記憶體配置
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --memory 1Gi

# 更新 CPU 配置
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --cpu 2

# 更新最小實例數
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --min-instances 1

# 更新最大實例數
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --max-instances 20
```

### 流量管理

```bash
# 部署新版本但不切換流量
gcloud run deploy fastapi-login-system \
  --image IMAGE_URL \
  --region asia-east1 \
  --no-traffic \
  --tag blue

# 將流量切換到最新版本
gcloud run services update-traffic fastapi-login-system \
  --region asia-east1 \
  --to-latest

# 分割流量（藍綠部署）
gcloud run services update-traffic fastapi-login-system \
  --region asia-east1 \
  --to-tags blue=50,green=50

# 查看流量分配
gcloud run services describe fastapi-login-system \
  --region asia-east1 \
  --format='value(status.traffic)'
```

### 回滾

```bash
# 查看修訂版本
gcloud run revisions list \
  --service fastapi-login-system \
  --region asia-east1

# 回滾到特定修訂版本
gcloud run services update-traffic fastapi-login-system \
  --region asia-east1 \
  --to-revisions REVISION_NAME=100
```

### 刪除服務

```bash
# 刪除 Cloud Run 服務
gcloud run services delete fastapi-login-system \
  --region asia-east1

# 刪除 Artifact Registry 儲存庫
gcloud artifacts repositories delete fastapi-login-system \
  --location asia-east1
```

## Artifact Registry 管理

### 查看映像

```bash
# 列出儲存庫
gcloud artifacts repositories list

# 列出映像
gcloud artifacts docker images list \
  asia-east1-docker.pkg.dev/YOUR_PROJECT_ID/fastapi-login-system

# 查看映像標籤
gcloud artifacts docker tags list \
  asia-east1-docker.pkg.dev/YOUR_PROJECT_ID/fastapi-login-system/fastapi-login-system
```

### 清理舊映像

```bash
# 刪除特定映像
gcloud artifacts docker images delete \
  asia-east1-docker.pkg.dev/YOUR_PROJECT_ID/fastapi-login-system/fastapi-login-system:TAG

# 刪除所有未標記的映像（需要腳本）
gcloud artifacts docker images list \
  asia-east1-docker.pkg.dev/YOUR_PROJECT_ID/fastapi-login-system \
  --filter="tags:*" \
  --format="get(package)" | while read image; do
    gcloud artifacts docker images delete "$image" --quiet
  done
```

## IAM 權限管理

```bash
# 檢視服務的 IAM 政策
gcloud run services get-iam-policy fastapi-login-system \
  --region asia-east1

# 允許所有人存取（公開服務）
gcloud run services add-iam-policy-binding fastapi-login-system \
  --region asia-east1 \
  --member="allUsers" \
  --role="roles/run.invoker"

# 移除公開存取
gcloud run services remove-iam-policy-binding fastapi-login-system \
  --region asia-east1 \
  --member="allUsers" \
  --role="roles/run.invoker"

# 授權特定服務帳號
gcloud run services add-iam-policy-binding fastapi-login-system \
  --region asia-east1 \
  --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
  --role="roles/run.invoker"
```

## 監控與除錯

### 測試服務

```bash
# 取得服務 URL
SERVICE_URL=$(gcloud run services describe fastapi-login-system \
  --region asia-east1 \
  --format='value(status.url)')

# 測試根路徑
curl $SERVICE_URL

# 測試登入
curl -X POST $SERVICE_URL/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user@example.com","password":"password123"}'

# 測試認證端點
TOKEN="YOUR_TOKEN_HERE"
curl -H "Authorization: Bearer $TOKEN" $SERVICE_URL/me
```

### 查看指標

```bash
# 在瀏覽器中開啟監控頁面
gcloud run services describe fastapi-login-system \
  --region asia-east1 \
  --format='value(status.url)' | \
  sed 's|https://||' | \
  xargs -I {} gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=fastapi-login-system"
```

## Secret Manager（進階）

### 使用 Secret Manager 儲存密鑰

```bash
# 建立 secret
echo -n "your-secret-key" | gcloud secrets create app-secret-key --data-file=-

# 授權 Cloud Run 存取 secret
gcloud secrets add-iam-policy-binding app-secret-key \
  --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# 在部署時使用 secret
gcloud run deploy fastapi-login-system \
  --image IMAGE_URL \
  --region asia-east1 \
  --set-secrets=SECRET_KEY=app-secret-key:latest
```

## 自動化腳本範例

### 快速部署腳本

```bash
#!/bin/bash
# quick-deploy.sh

PROJECT_ID=$(gcloud config get-value project)
REGION="asia-east1"
SERVICE="fastapi-login-system"
IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$SERVICE/$SERVICE:$(git rev-parse --short HEAD)"

echo "建構映像..."
docker build -t $IMAGE .

echo "推送映像..."
docker push $IMAGE

echo "部署到 Cloud Run..."
gcloud run deploy $SERVICE \
  --image $IMAGE \
  --region $REGION \
  --allow-unauthenticated \
  --port 1234

echo "部署完成！"
gcloud run services describe $SERVICE \
  --region $REGION \
  --format='value(status.url)'
```

### 備份配置腳本

```bash
#!/bin/bash
# backup-config.sh

gcloud run services describe fastapi-login-system \
  --region asia-east1 \
  --format yaml > cloud-run-config-backup.yaml

echo "配置已備份到 cloud-run-config-backup.yaml"
```

## 疑難排解

```bash
# 檢查服務狀態
gcloud run services describe fastapi-login-system \
  --region asia-east1 \
  --format='value(status.conditions)'

# 檢查最新的錯誤日誌
gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" \
  --limit=20 \
  --format=json

# 檢查部署歷史
gcloud run revisions list \
  --service fastapi-login-system \
  --region asia-east1

# 檢查配額使用情況
gcloud compute project-info describe --project YOUR_PROJECT_ID
```

## 成本優化

```bash
# 設定最小實例數為 0（無流量時不收費）
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --min-instances 0

# 降低記憶體配置
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --memory 256Mi

# 設定請求逾時
gcloud run services update fastapi-login-system \
  --region asia-east1 \
  --timeout 60

# 查看計費資訊
gcloud billing accounts list
```

## 參考資源

- [Cloud Run 文件](https://cloud.google.com/run/docs)
- [gcloud CLI 參考](https://cloud.google.com/sdk/gcloud/reference/run)
- [Cloud Run 定價](https://cloud.google.com/run/pricing)
- [最佳實務](https://cloud.google.com/run/docs/best-practices)
