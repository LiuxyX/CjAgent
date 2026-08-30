# routers/auth.py
from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

router = APIRouter()

@router.get("/api/v1/login", response_class=PlainTextResponse)
def verify_login(account: str, pwd: str):
    # 💡 这里就是你的“模拟数据库”
    # 以后真正连 MySQL 时，只需要把这个字典换成 SQL 查询即可
    mock_users_db = {
        "admin": "123456",       # 超级管理员
        "wangwei": "888888",     # 跃进河巡检员：王伟
        "lishu": "water2026"     # 长明水库巡检员：李舒
    }

    # 1. 判断账号是否存在
    if account not in mock_users_db:
        return "FAIL:ACCOUNT_NOT_FOUND"
    
    # 2. 判断密码是否匹配
    if mock_users_db[account] == pwd:
        return "SUCCESS"
    else:
        return "FAIL:WRONG_PASSWORD"