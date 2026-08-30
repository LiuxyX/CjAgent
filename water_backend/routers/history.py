# routers/history.py
import socket
from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

# 1. 核心变化：原来是 app = FastAPI()，现在变成 router = APIRouter()
router = APIRouter()

# 💡 自动获取本机 IP 的函数
def get_host_ip():
    """自动获取本机的局域网 IP 地址"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()
    return ip

# 2. 路由装饰器从 @app.get 变成 @router.get
# 接收仓颉发来的 GET 请求
@router.get("/api/v1/history", response_class=PlainTextResponse)
def query_history_api(date: str, loc: str, event: str):
    
    # 🚀 每次查询时，自动获取真实的本机 IP
    local_ip = get_host_ip()
    
    # 💡 动态拼装 URL，彻底告别手动改 IP！
    mock_db = [
        ("2026-03-14 10:15", "跃进河", "巡逻车", f"http://{local_ip}:8000/static/patrol_1015.mp4"),
        ("2026-03-14 15:00", "跃进河三号桥", "非法垂钓", f"http://{local_ip}:8000/static/fishing1_fixed.mp4"),
        ("2026-03-15 09:00", "跃进河", "水面垃圾", f"http://{local_ip}:8000/static/rubbish_fixed.mp4"),
        ("2026-03-15 14:00", "跃进河", "非法垂钓", f"http://{local_ip}:8000/static/fishing2_fixed.mp4"),
        ("2026-03-13 11:30", "长明水库", "违规下河", f"http://{local_ip}:8000/static/gtriver_fixed.mp4")
    ]

    result_text = ""
    match_count = 0
    first_video_url = ""

    # Python 负责执行筛选逻辑
    for r_time, r_loc, r_event, r_video in mock_db:
        date_match = (date == "all") or (date in r_time)
        loc_match = (loc == "all") or (loc in r_loc)
        event_match = (event == "all") or (event in r_event)

        if date_match and loc_match and event_match:
            match_count += 1
            result_text += f"- 时间:{r_time}, 地点:{r_loc}, 事件:{r_event}。\n"
            if r_video and not first_video_url:
                first_video_url = r_video

    # 组装返回给仓颉的自然语言
    if match_count > 0:
        final_msg = f"查询成功，共找到 {match_count} 条记录：\n{result_text}"
        if first_video_url:
            final_msg += f"已为您调出相关监控回放。视频源:{first_video_url}"
        return final_msg
    else:
        return "数据库中未查询到符合条件的历史记录。"