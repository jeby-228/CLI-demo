"""
測試 FastAPI 會員登入系統
"""
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_read_root():
    """測試根路徑"""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()
    assert "歡迎" in response.json()["message"]


def test_login_success():
    """測試成功登入"""
    response = client.post("/login", json={
        "username": "user@example.com",
        "password": "password123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["token_type"] == "bearer"


def test_login_wrong_password():
    """測試錯誤密碼"""
    response = client.post("/login", json={
        "username": "user@example.com",
        "password": "wrongpassword"
    })
    assert response.status_code == 401
    assert "detail" in response.json()


def test_login_nonexistent_user():
    """測試不存在的使用者"""
    response = client.post("/login", json={
        "username": "nonexistent@example.com",
        "password": "password123"
    })
    assert response.status_code == 401


def test_get_current_user_with_valid_token():
    """測試使用有效 Token 取得使用者資訊"""
    # 先登入取得 Token
    login_response = client.post("/login", json={
        "username": "user@example.com",
        "password": "password123"
    })
    token = login_response.json()["access_token"]
    
    # 使用 Token 取得使用者資訊
    response = client.get("/me", headers={
        "Authorization": f"Bearer {token}"
    })
    assert response.status_code == 200
    assert response.json()["username"] == "user@example.com"
    assert "full_name" in response.json()


def test_get_current_user_without_token():
    """測試沒有 Token 的情況"""
    response = client.get("/me")
    assert response.status_code == 403


def test_get_current_user_with_invalid_token():
    """測試使用無效 Token"""
    response = client.get("/me", headers={
        "Authorization": "Bearer invalid_token_here"
    })
    assert response.status_code == 401
