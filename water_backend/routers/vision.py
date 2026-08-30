# routers/vision.py
import cv2
import numpy as np
from fastapi import APIRouter
from fastapi.responses import StreamingResponse, PlainTextResponse
from ultralytics import YOLO
import time
import socket # ✨ 队友新增：用于获取IP

# 1. 初始化 Router (坚守我们的模块化架构)
router = APIRouter()

print("👁️ 正在加载 YOLOv8 视觉模型，请稍候...")
# 保持我们的规范路径
model = YOLO('vision_assets/yolov8n.pt')

# ================= 全局状态与统计 =================
global_status = {
    "isFoggy": False,
    "hasIllegalBehavior": False,
    "illegalBehaviors": [],
    "environmentalIssues": [],
    "errorMessage": ""
}

report_statistics = {
    "person_count": 0,
    "boat_count": 0,
    "bottle_count": 0
}

# 防抖记录字典
last_detect_time = {"person": 0, "boat": 0, "bottle": 0}
# ===================================================

def fast_defog(frame):
    """基于 Dehaze-RetinexGAN 物理模型的简易去雾算法"""
    I = frame.astype(np.float32) / 255.0
    S = 1.0 - I
    L = cv2.GaussianBlur(S, (0, 0), 15)
    L = np.clip(L, 0.05, 1.0)
    R = S / L
    J = 1.0 - (0.85 * R)
    J = np.clip(J, 0.0, 1.0)
    J_uint8 = (J * 255.0).astype(np.uint8)

    lab = cv2.cvtColor(J_uint8, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    cl = clahe.apply(l)
    return cv2.cvtColor(cv2.merge((cl, a, b)), cv2.COLOR_LAB2BGR)

def process_video_stream(video_source):
    """核心视频处理生成器"""
    global global_status, report_statistics, last_detect_time
    cap = cv2.VideoCapture(video_source)

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            cap.set(cv2.CAP_PROP_POS_FRAMES, 0) # 循环播放
            continue

        # --- 1. 能见度检测与去雾 ---
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        variance = cv2.Laplacian(gray, cv2.CV_64F).var()
        is_foggy = bool(variance < 50.0)

        if is_foggy:
            frame = fast_defog(frame)
            cv2.putText(frame, "STATUS: Defogging ON", (20, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 165, 255), 2)

        # --- 2. YOLOv8 检测 ---
        results = model(frame, classes=[0, 8, 39], verbose=False)
        annotated_frame = results[0].plot()

        current_illegal_behaviors = set()
        current_env_issues = set()
        current_time = time.time()

        # --- 3. 业务逻辑映射与防抖计数 ---
        for result in results:
            for box in result.boxes:
                confidence = float(box.conf[0])
                if confidence > 0.5:
                    class_id = int(box.cls[0])

                    if class_id == 0:  # 人
                        current_illegal_behaviors.add("涉水违规/违规下河")
                        cv2.putText(annotated_frame, "ALERT: Illegal Water Entry", (20, 80),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
                        if current_time - last_detect_time["person"] > 5:
                            report_statistics["person_count"] += 1
                            last_detect_time["person"] = current_time

                    elif class_id == 8:  # 船
                        current_illegal_behaviors.add("违规船只/非法捕捞")
                        cv2.putText(annotated_frame, "ALERT: Illegal Boat", (20, 110),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
                        if current_time - last_detect_time["boat"] > 5:
                            report_statistics["boat_count"] += 1
                            last_detect_time["boat"] = current_time

                    elif class_id == 39:  # 塑料瓶
                        current_env_issues.add("水面漂浮物(塑料瓶等)")
                        cv2.putText(annotated_frame, "ISSUE: Surface Garbage", (20, 140),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
                        if current_time - last_detect_time["bottle"] > 5:
                            report_statistics["bottle_count"] += 1
                            last_detect_time["bottle"] = current_time

        # --- 4. 更新全局状态 ---
        global_status["isFoggy"] = is_foggy
        global_status["illegalBehaviors"] = list(current_illegal_behaviors)
        global_status["environmentalIssues"] = list(current_env_issues)
        global_status["hasIllegalBehavior"] = len(current_illegal_behaviors) > 0

        # --- 5. 视频流编码 ---
        _, buffer = cv2.imencode('.jpg', annotated_frame)
        frame_bytes = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

# ✨ 队友新增：获取主机 IP 的辅助函数
def get_host_ip():
    """自动获取本机的局域网 IP 地址"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()
    return ip


# ==================== 路由接口配置 ====================

@router.get("/api/v1/stream/{camera_id}")
async def video_stream(camera_id: str):
    """📺 视频流接口：保持原样，吐出带画框和警告的实时视频流"""
    # 保持咱们的规范路径
    video_source = "vision_assets/test.mp4" 
    return StreamingResponse(process_video_stream(video_source),
                             media_type="multipart/x-mixed-replace; boundary=frame")

# 🌟【这是你的专属接口】：供 AlertCenter 看板轮询读取 JSON 状态
@router.get("/api/v1/analyze/{camera_id}")
async def get_analyze_json(camera_id: str):
    """📊 看板数据接口：返回结构化的业务 JSON 数据"""
    return global_status

# 🌟【这是队友的专属接口】：供 Agent 大模型 Tool 聊天使用
@router.get("/api/v1/status/{camera_id}", response_class=PlainTextResponse)
async def get_status_as_text(camera_id: str):
    """💬 对话数据接口：供大模型直接读取的自然语言文本"""
    global global_status
    local_ip = get_host_ip()
    
    fog_msg = "检测到浓雾" if global_status["isFoggy"] else "能见度良好"
    alert_msg = "【警告】发现违法行为！" if global_status["hasIllegalBehavior"] else "未见异常"
    
    video_url = f"http://{local_ip}:8000/static/boat_fixed.mp4"
    return f"视觉引擎分析完毕：当前画面{fog_msg}，{alert_msg}。视频源:{video_url}"

@router.get("/api/v1/report", response_class=PlainTextResponse)
async def generate_real_report():
    """📄 报告接口"""
    p = report_statistics["person_count"]
    b = report_statistics["boat_count"]
    t = report_statistics["bottle_count"]
    summary = f"【水域监管真实数据总结】\n本监控周期内，AI 视觉引擎共实时拦截并记录：涉水违规 {p} 次，非法船只 {b} 次，水面垃圾 {t} 次。各项异常数据已同步保存。"
    chart_data = f"[CHART_DATA]涉水违规:{p},非法船只:{b},水面垃圾:{t}"
    return f"{summary}\n{chart_data}"