import random
import time
import socket
import uvicorn
import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

# 🚀 修改 1：明确标明这是 Mock（模拟）服务器
app = FastAPI(title="Water AI Mock Alert Server (模拟测试专用)")

# 挂载静态文件目录 (这部分保持不变)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
static_path = os.path.join(BASE_DIR, "static")
if not os.path.exists(static_path):
    os.makedirs(static_path)
app.mount("/static", StaticFiles(directory="static"), name="static")

def get_host_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

LOCAL_IP = get_host_ip()
# 明确它占用 8002 测试端口，不与 8000 真实端口冲突
PORT = 8002 

# 🚀 修改 2：变量名加上 mock_ 前缀，表示这是伪造的状态
mock_alert_state = {
    "hasIllegalBehavior": False,
    "behaviorName": "",
    "location": "",  
    "startTime": 0,
    "duration": 8  # 假警报持续 8 秒
}

# 🚀 接口路径保持不变（为了前端不需要改代码），但函数名加上 mock_
@app.get("/api/v1/status/test")
async def get_mock_status():
    global mock_alert_state
    now = time.time()
    ts = int(now * 1000)
    
    # 随机触发逻辑
    if not mock_alert_state["hasIllegalBehavior"] and random.random() < 0.15:
        mock_alert_state["hasIllegalBehavior"] = True
        mock_alert_state["behaviorName"] = random.choice(["涉水违规", "非法捕捞"])
        mock_alert_state["location"] = random.choice(["跃进河上游段", "跃进河中游段", "跃进河下游段"])
        mock_alert_state["startTime"] = now
        # 🚀 修改 3：控制台日志明确标出这是 MOCK 数据
        print(f"⚠️ [MOCK 模拟触发]: {mock_alert_state['location']} - {mock_alert_state['behaviorName']}")

    # 自动解除逻辑
    if mock_alert_state["hasIllegalBehavior"] and (now - mock_alert_state["startTime"] > mock_alert_state["duration"]):
        mock_alert_state["hasIllegalBehavior"] = False
        print("✅ [MOCK 模拟解除]: 恢复正常监控")

    if mock_alert_state["hasIllegalBehavior"]:
        video_url = f"http://{LOCAL_IP}:{PORT}/static/boat_fixed.mp4?t={ts}"
        
        return {
            "hasIllegalBehavior": True,
            "illegalBehaviors": [mock_alert_state["behaviorName"]],
            "location": mock_alert_state["location"],
            "videoUrl": video_url,
            "message": f"警告：检测到{mock_alert_state['behaviorName']}"
        }
    else:
        # 💡 这里建议确保你的 static 目录下确实有一个占位视频，比如 default.mp4
        default_video = "boat_fixed.mp4" 
        return {
            "hasIllegalBehavior": False,
            "videoUrl": f"http://{LOCAL_IP}:{PORT}/static/{default_video}?t={ts}",
            "message": "系统巡检正常"
        }

@app.get("/")
async def root():
    return {"status": "Mock Service is running", "api_url": "/api/v1/status/test"}

if __name__ == "__main__":
    print(f"\n=================================================")
    print(f"🤡 MOCK 模拟服务器已启动！(专供前端 UI 测试)")
    print(f"=================================================")
    print(f"🔗 状态接口: http://{LOCAL_IP}:{PORT}/api/v1/status/test")
    print(f"📂 静态资源: http://{LOCAL_IP}:{PORT}/static/boat_fixed.mp4")
    print(f"=================================================\n")
    uvicorn.run(app, host="0.0.0.0", port=PORT)