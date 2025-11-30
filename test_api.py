"""
測試 FastAPI 登入功能
"""
import requests
import time
import subprocess
import sys
import os

def test_login_system():
    # 啟動服務器
    print("正在啟動 FastAPI 服務器...")
    server = subprocess.Popen(
        [sys.executable, "main.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=os.path.dirname(os.path.abspath(__file__))
    )
    
    # 等待服務器啟動
    time.sleep(5)
    
    BASE_URL = "http://localhost:8000"
    
    try:
        # 測試 1: 根路徑
        print("\n測試 1: 訪問根路徑")
        response = requests.get(f"{BASE_URL}/")
        print(f"狀態碼: {response.status_code}")
        print(f"回應: {response.json()}")
        assert response.status_code == 200, "根路徑應該返回 200"
        
        # 測試 2: 正確的登入
        print("\n測試 2: 使用正確的帳號密碼登入")
        login_data = {
            "username": "user@example.com",
            "password": "password123"
        }
        response = requests.post(f"{BASE_URL}/login", json=login_data)
        print(f"狀態碼: {response.status_code}")
        print(f"回應: {response.json()}")
        assert response.status_code == 200, "正確登入應該返回 200"
        
        token_data = response.json()
        assert "access_token" in token_data, "應該包含 access_token"
        assert "token_type" in token_data, "應該包含 token_type"
        access_token = token_data["access_token"]
        print(f"✓ 成功取得 Token: {access_token[:20]}...")
        
        # 測試 3: 錯誤的密碼
        print("\n測試 3: 使用錯誤的密碼登入")
        wrong_login = {
            "username": "user@example.com",
            "password": "wrongpassword"
        }
        response = requests.post(f"{BASE_URL}/login", json=wrong_login)
        print(f"狀態碼: {response.status_code}")
        print(f"回應: {response.json()}")
        assert response.status_code == 401, "錯誤密碼應該返回 401"
        print("✓ 正確拒絕錯誤密碼")
        
        # 測試 4: 不存在的使用者
        print("\n測試 4: 使用不存在的帳號登入")
        fake_login = {
            "username": "fake@example.com",
            "password": "password123"
        }
        response = requests.post(f"{BASE_URL}/login", json=fake_login)
        print(f"狀態碼: {response.status_code}")
        assert response.status_code == 401, "不存在的帳號應該返回 401"
        print("✓ 正確拒絕不存在的帳號")
        
        # 測試 5: 使用 Token 取得使用者資訊
        print("\n測試 5: 使用 Token 取得使用者資訊")
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        response = requests.get(f"{BASE_URL}/me", headers=headers)
        print(f"狀態碼: {response.status_code}")
        print(f"回應: {response.json()}")
        assert response.status_code == 200, "有效 Token 應該返回 200"
        
        user_data = response.json()
        assert user_data["username"] == "user@example.com", "應該返回正確的使用者名稱"
        print("✓ 成功取得使用者資訊")
        
        # 測試 6: 使用無效的 Token
        print("\n測試 6: 使用無效的 Token")
        invalid_headers = {
            "Authorization": "Bearer invalid_token_here"
        }
        response = requests.get(f"{BASE_URL}/me", headers=invalid_headers)
        print(f"狀態碼: {response.status_code}")
        assert response.status_code == 401, "無效 Token 應該返回 401"
        print("✓ 正確拒絕無效 Token")
        
        print("\n" + "="*50)
        print("所有測試通過！✓")
        print("="*50)
        
    except AssertionError as e:
        print(f"\n測試失敗: {e}")
        return False
    except requests.exceptions.ConnectionError:
        print("\n無法連接到服務器，請確保服務器正在運行")
        return False
    except Exception as e:
        print(f"\n測試過程中發生錯誤: {e}")
        return False
    finally:
        # 關閉服務器
        print("\n正在關閉服務器...")
        server.terminate()
        server.wait()
    
    return True

if __name__ == "__main__":
    # 先檢查是否已安裝必要套件
    try:
        import fastapi
        import uvicorn
        import jwt
        import passlib
        print("✓ 所有依賴套件已安裝")
    except ImportError as e:
        print(f"缺少必要套件: {e}")
        print("請先執行: pip install -r requirements.txt")
        sys.exit(1)
    
    success = test_login_system()
    sys.exit(0 if success else 1)
