# main.py
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

# 导入你刚刚写的两个子模块
from routers import history, device, auth , vision

app = FastAPI(
    title="水域监管智能体统一后端 API",
    description="包含历史视频检索与设备状态管理模块"
)

# 1. 统一挂载静态文件目录 (全局只需要写一次)
app.mount("/static", StaticFiles(directory="static"), name="static")

# 2. 整合子路由
# tags 会让你的 Swagger 文档自动分类，非常清晰
app.include_router(history.router, tags=["历史记录模块"])
app.include_router(device.router, tags=["设备管理模块"])
app.include_router(auth.router, tags=["权限认证模块"])
app.include_router(vision.router, tags=["实时视觉感知模块"])

# 💡 如果后续新增了比如"天气预报"模块 weather.py
# 只需要在这里加一行：app.include_router(weather.router, tags=["气象模块"])





