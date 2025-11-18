#!/bin/bash
# GCP 設定腳本
# 此腳本協助設定 GCP 環境以供 CI/CD 使用

set -e

echo "=================================="
echo "GCP CI/CD 環境設定腳本"
echo "=================================="
echo ""

# 檢查是否已安裝 gcloud
if ! command -v gcloud &> /dev/null; then
    echo "錯誤: 未找到 gcloud 命令列工具"
    echo "請先安裝 Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# 取得專案 ID
echo "步驟 1/7: 取得 GCP 專案資訊"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    echo "未設定 GCP 專案。"
    read -p "請輸入您的 GCP 專案 ID: " PROJECT_ID
    gcloud config set project $PROJECT_ID
fi

echo "使用專案: $PROJECT_ID"
echo ""

# 啟用必要的 API
echo "步驟 2/7: 啟用必要的 GCP API..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerregistry.googleapis.com
echo "✓ API 已啟用"
echo ""

# 建立 Artifact Registry 儲存庫
echo "步驟 3/7: 建立 Artifact Registry 儲存庫..."
REPO_NAME="fastapi-login-system"
REGION="asia-east1"

if gcloud artifacts repositories describe $REPO_NAME --location=$REGION &>/dev/null; then
    echo "✓ 儲存庫 $REPO_NAME 已存在"
else
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="FastAPI login system Docker images"
    echo "✓ 儲存庫已建立"
fi
echo ""

# 建立服務帳號
echo "步驟 4/7: 建立服務帳號..."
SA_NAME="github-actions"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
    echo "✓ 服務帳號 $SA_EMAIL 已存在"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="GitHub Actions Service Account"
    echo "✓ 服務帳號已建立"
fi
echo ""

# 授予權限
echo "步驟 5/7: 授予服務帳號權限..."

ROLES=(
    "roles/run.admin"
    "roles/artifactregistry.writer"
    "roles/iam.serviceAccountUser"
    "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="$ROLE" \
        --condition=None \
        > /dev/null 2>&1 || true
    echo "  ✓ 已授予 $ROLE"
done
echo ""

# 建立服務帳號金鑰
echo "步驟 6/7: 建立服務帳號金鑰..."
KEY_FILE="gcp-sa-key.json"

if [ -f "$KEY_FILE" ]; then
    read -p "金鑰檔案 $KEY_FILE 已存在。要重新建立嗎？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "跳過金鑰建立"
    else
        rm $KEY_FILE
        gcloud iam service-accounts keys create $KEY_FILE \
            --iam-account=$SA_EMAIL
        echo "✓ 金鑰已建立: $KEY_FILE"
    fi
else
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SA_EMAIL
    echo "✓ 金鑰已建立: $KEY_FILE"
fi
echo ""

# 生成 SECRET_KEY
echo "步驟 7/7: 生成應用程式密鑰..."
if command -v python3 &> /dev/null; then
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    echo "✓ 密鑰已生成"
else
    SECRET_KEY="PLEASE-GENERATE-A-SECURE-RANDOM-KEY"
    echo "⚠ 無法自動生成密鑰，請手動生成"
fi
echo ""

# 顯示摘要
echo "=================================="
echo "設定完成！"
echo "=================================="
echo ""
echo "請在 GitHub 儲存庫的 Settings > Secrets and variables > Actions 中新增以下 secrets："
echo ""
echo "1. GCP_PROJECT_ID"
echo "   值: $PROJECT_ID"
echo ""
echo "2. GCP_SA_KEY"
echo "   值: $(cat $KEY_FILE 2>/dev/null | head -c 50)... (完整內容請開啟 $KEY_FILE)"
echo ""
echo "3. SECRET_KEY"
echo "   值: $SECRET_KEY"
echo ""
echo "⚠️  重要提醒："
echo "  - 請妥善保管 $KEY_FILE 檔案"
echo "  - 請勿將金鑰檔案提交到 Git 儲存庫"
echo "  - 設定完成後建議刪除本地的金鑰檔案"
echo ""
echo "詳細說明請參考: GCP_DEPLOYMENT.md"
echo ""
