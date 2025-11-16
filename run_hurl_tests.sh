#!/bin/bash

# Hurl 測試執行腳本
# 用於啟動 FastAPI 服務並執行 Hurl 測試

set -e

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}FastAPI 會員登入系統 - Hurl 測試${NC}"
echo "========================================"

# 檢查 Hurl 是否已安裝
if ! command -v hurl &> /dev/null; then
    echo -e "${RED}錯誤: Hurl 未安裝${NC}"
    echo "請執行以下指令安裝 Hurl:"
    echo "  curl --location --remote-name https://github.com/Orange-OpenSource/hurl/releases/download/4.3.0/hurl_4.3.0_amd64.deb"
    echo "  sudo dpkg -i hurl_4.3.0_amd64.deb"
    exit 1
fi

echo -e "${GREEN}✓ Hurl 已安裝: $(hurl --version | head -n 1)${NC}"
echo ""

# 檢查測試模式
MODE=${1:-local}

if [ "$MODE" == "docker" ]; then
    echo -e "${YELLOW}模式: Docker (port 1234)${NC}"
    TEST_FILE="test_api_docker.hurl"
    PORT=1234
    
    # 檢查 Docker 容器是否運行
    if ! docker ps | grep -q fastapi-login-system; then
        echo -e "${YELLOW}警告: Docker 容器未運行${NC}"
        echo "啟動 Docker 容器..."
        docker-compose up -d
        echo "等待服務啟動..."
        sleep 5
    fi
else
    echo -e "${YELLOW}模式: 本地 (port 8000)${NC}"
    TEST_FILE="test_api.hurl"
    PORT=8000
    
    # 檢查是否需要啟動本地服務器
    if ! curl -s http://localhost:$PORT/ > /dev/null 2>&1; then
        echo -e "${YELLOW}啟動 FastAPI 服務器...${NC}"
        python main.py &
        SERVER_PID=$!
        
        # 等待服務器啟動
        echo "等待服務器啟動..."
        for i in {1..10}; do
            if curl -s http://localhost:$PORT/ > /dev/null 2>&1; then
                echo -e "${GREEN}✓ 服務器已啟動${NC}"
                break
            fi
            sleep 1
        done
        
        # 設置陷阱以在腳本退出時關閉服務器
        trap "echo ''; echo '關閉服務器...'; kill $SERVER_PID 2>/dev/null" EXIT
    else
        echo -e "${GREEN}✓ 服務器已在運行${NC}"
    fi
fi

echo ""
echo "========================================"
echo -e "${YELLOW}執行 Hurl 測試...${NC}"
echo "========================================"
echo ""

# 執行 Hurl 測試
if hurl --test --verbose "$TEST_FILE"; then
    echo ""
    echo "========================================"
    echo -e "${GREEN}✓ 所有測試通過！${NC}"
    echo "========================================"
    exit 0
else
    echo ""
    echo "========================================"
    echo -e "${RED}✗ 測試失敗${NC}"
    echo "========================================"
    exit 1
fi
