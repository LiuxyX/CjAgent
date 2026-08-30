# routers/device.py
from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

# 1. 核心变化：使用 APIRouter
router = APIRouter()

# 2. 路由装饰器改为 @router.get
@router.get("/api/v1/device_status", response_class=PlainTextResponse)
def get_device_status(area: str):
    # 💡 模拟各分局设备数据，以后可以改成调取海康威视或大华的 API
    status_data = {
        "跃进河": {
            "total": 15, "online": 14, "offline": 1, 
            "detail": "故障设备：三号桥辅路探头，离线时间：今天 08:30"
        },
        "长明水库": {
            "total": 10, "online": 10, "offline": 0, "detail": "运行良好"
        },
        "all": {
            "total": 120, "online": 115, "offline": 5, "detail": "全市运行平稳"
        }
    }

    # 简单的逻辑匹配
    target = None
    if area == "all":
        target = status_data["all"]
    else:
        # 模糊匹配
        for key in status_data:
            if key in area:
                target = status_data[key]
                break

    if target:
        rate = round((target["online"] / target["total"]) * 100, 1)
        res = (f"{area}分局总计 {target['total']} 个摄像头，"
               f"当前在线 {target['online']} 个，离线 {target['offline']} 个。"
               f"({target['detail']})。视频在线率 {rate}%。")
        return res
    else:
        return f"数据库中未找到关于 '{area}' 区域的设备实时状态。"