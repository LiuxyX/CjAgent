package ohos_app_cangjie_entry.agent

import ohos.net.http.*
import agent_vision_connector.*
import std.sync.*
import ohos_app_cangjie_entry.config.REAL_SERVER_URL




// ==========================================
// 1. 工具接口全面升级为“异步回调”机制
// ==========================================
public interface Tool {
    func getName(): String
    func desc(): String
    func run(arg: String, onComplete: (String) -> Unit): Unit
}


// ==========================================
// 2. 视觉处理工具 (告别死锁)
// ==========================================
public class VisionTool <: Tool {
    // 🚀 坚守全局配置：彻底删掉写死的 IP，直接使用真实的后端地址！
    private let serverUrl = REAL_SERVER_URL

    public func getName() { "vision_analysis" }
    // 融合两者的描述信息
    public func desc() { "视觉分析工具。支持去雾检测、目标识别。传入摄像头ID。返回AI研判文字和视频播放地址。（如果用户没有提供摄像头ID，则默认为0）" }

    public func run(arg: String, onComplete: (String) -> Unit): Unit {
        let httpRequest = createHttp()
        let counter = SyncCounter(1) // 🎯 保留队友的同步计数器机制

        // 🎯 使用 Python 端返回纯文本的新接口
        let cameraId = if(arg.trimAscii().isEmpty()) { "test" } else { arg.trimAscii() }
        let url = "${serverUrl}/api/v1/status/${cameraId}"

        try {
            let options = HttpRequestOptions(method: RequestMethod.Get)

            httpRequest.request(url, options) { err, response =>
                try {
                    match (err) {
                        case Some(e) => onComplete("无法连接视觉服务器: ${e.toString()}")
                        case None =>
                            match (response) {
                                case Some(res) =>
                                    if (res.responseCode == 200) {
                                        let rawData = match (res.result) {
                                            case HttpData.StringData(s) => s
                                            case HttpData.ArrayData(b) => String.fromUtf8(b)
                                            case _ => ""
                                        }
                                        // 🎯 告别手动解析 JSON，直接把 Python 返回的自然语言喂给大模型
                                        if (!rawData.isEmpty()) {
                                            onComplete(rawData)
                                        }
                                    } else {
                                        onComplete("服务器错误码: ${res.responseCode}")
                                    }
                                case None => onComplete("未收到服务器响应")
                            }
                    }
                } finally {
                    counter.dec() // 🎯 拿到数据后，释放锁
                }
            }

            // 🎯 关键：主线程在这里最多等待 5 秒，防止大模型工具链断裂
            counter.waitUntilZero(timeout: 5000 * Duration.millisecond)

        } catch (e: Exception) {
            onComplete("视觉工具运行异常: ${e.toString()}")
        } finally {
            httpRequest.destroy()
        }
    }
}

// ==========================================
// 3. 真实监管报告生成工具 (告别死锁)
// ==========================================
public class ReportTool <: Tool {
    private let serverUrl = REAL_SERVER_URL

    public func getName() { "generate_report" }
    public func desc() { "生成并拉取水域监管的真实数据报告。当用户要求生成报告、总结、查看统计图表时必须调用此工具。" }

    public func run(arg: String, onComplete: (String) -> Unit): Unit {
        let httpRequest = createHttp()
        let url = "${serverUrl}/api/v1/report"

        let options = HttpRequestOptions(method: RequestMethod.Get)

        httpRequest.request(url, options) { err, response =>
            try {
                match (err) {
                    case Some(e) => onComplete("请求发生错误: ${e.toString()}")
                    case None =>
                        match (response) {
                            case Some(res) =>
                                if (res.responseCode == 200) {
                                    match (res.result) {
                                        case HttpData.StringData(s) => onComplete(s)
                                        case HttpData.ArrayData(b) => onComplete(String.fromUtf8(b))
                                        case _ => onComplete("数据解析失败")
                                    }
                                } else {
                                    onComplete("请求失败，状态码: ${res.responseCode}")
                                }
                            case None => onComplete("无响应")
                        }
                }
            } finally {
                httpRequest.destroy()
            }
        }
    }
}

/*
用于管理设备状态
py端返回的是纯文本：
接口返回的是 纯文本 (PlainText)，根据你的匹配结果有两种情况：
匹配成功 (HTTP 200):
返回一段自然语言描述，包含：总数、在线数、离线数、故障细节以及计算好的在线率。

示例："跃进河分局总计 15 个摄像头，当前在线 14 个，离线 1 个。(故障设备：三号桥辅路探头...)。视频在线率 93.3%。"

匹配失败 (HTTP 200):
返回提示信息。

示例："数据库中未找到关于 '某某区域' 区域的设备实时状态。"

*/
public class DeviceStatusTool <: Tool {
    // 🔥 统一指向你的 Python 后端地址
    //——————————————————————换地址——————————————————————
    private let serverUrl = REAL_SERVER_URL

    public func getName() { "check_device_status" }

    public func desc() {
        "查询监控设备的在线状态、在线率、是否掉线。参数：区域名称(如：跃进河分局，若查全局传 all)"
    }

    public func run(arg: String, onComplete: (String) -> Unit):Unit {
        let area = arg.trimAscii()

        // 1. 构建请求 URL (对中文参数进行简单的拼装)
        let url = "${serverUrl}/api/v1/device_status?area=${area}"

        let httpRequest = createHttp()
        let counter = SyncCounter(1)


        try {
            let options = HttpRequestOptions(method: RequestMethod.Get)

            httpRequest.request(url, options) { err, response =>
                try {
                    match (err) {
                        case Some(e) => onComplete("请求发生错误: ${e.toString()}")
                        case None =>
                            match (response) {
                                case Some(res) =>
                                    if (res.responseCode == 200) {
                                        let rawData = match (res.result) {
                                            case HttpData.StringData(s) => s
                                            case HttpData.ArrayData(b) => String.fromUtf8(b)
                                            case _ => ""
                                        }
                                        if (!rawData.isEmpty()) {onComplete("${rawData}")}
                                    } else {
                                        onComplete("请求失败，状态码: ${res.responseCode}")
                                    }
                                case None => ()
                            }
                    }
                } finally {
                    counter.dec()
                }
            }

            counter.waitUntilZero(timeout: 5000 * Duration.millisecond)
        } catch (e: Exception) {
            onComplete("网络异常: ${e.toString()}")
        } finally {
            httpRequest.destroy()
        }

    }
}

/*
用于管理历史记录
用户在鸿蒙 APP 里问：“查一下昨天跃进河三号桥的非法垂钓记录”。
仓颉 Agent 大脑提取参数，生成工具调用。
HistoryQueryTool 发起网络请求 GET /api/v1/history?date=2026-03-10...。
Python 收到请求，在自己的 mock_db 里找到对应记录，拼好文字返回。
仓颉拿到这段话，大模型原样输出。
前端 UI 看到 视频源:xxx.mp4，瞬间拉起弹窗播放视频
*/

public class HistoryQueryTool <: Tool {
    // 🔥 指向你的 Python 后端服务器
    //—————————————————————————————————————要换地址—————————————————————————————————————————————————
    private let serverUrl = REAL_SERVER_URL

    public func getName() { "query_history" }

    public func desc() {
        "检索历史监控事件。参数必须严格按逗号分隔，格式：时间(YYYY-MM-DD或YYYY-MM-DD HH),地点,事件类型。如果不限定某项，请用 'all'。例如查今天上午10点跃进河的垂钓，参数为：2026-03-11 10,跃进河,非法垂钓。查全天采砂则为：2025-03-11,all,非法采砂。"
    }

    private func urlEncode(input: String): String {
        let bytes = input.toArray()
        var encoded = ""
        for (b in bytes) {
            if ((b >= 48 && b <= 57) || // 0-9
                (b >= 65 && b <= 90) || // A-Z
                (b >= 97 && b <= 122) || // a-z
                b == 45 || b == 95 || b == 46 || b == 126) {
                encoded += String.fromUtf8([b])
            } else {
                encoded += "%" + toHexPair(b)
            }
        }
        return encoded
    }

    // 修正：彻底手动控制输出，不给插值字符串“发挥”的空间
    private func toHexPair(b: UInt8): String {
        let high = Int64((b >> 4) & 0x0F)
        let low = Int64(b & 0x0F)
        return getHexChar(high) + getHexChar(low)
    }

    // 修正：通过简单的分支判断，强制返回字符串格式的字符
    private func getHexChar(v: Int64): String {
        if (v == 0) { return "0" }
        if (v == 1) { return "1" }
        if (v == 2) { return "2" }
        if (v == 3) { return "3" }
        if (v == 4) { return "4" }
        if (v == 5) { return "5" }
        if (v == 6) { return "6" }
        if (v == 7) { return "7" }
        if (v == 8) { return "8" }
        if (v == 9) { return "9" }
        if (v == 10) { return "A" }
        if (v == 11) { return "B" }
        if (v == 12) { return "C" }
        if (v == 13) { return "D" }
        if (v == 14) { return "E" }
        if (v == 15) { return "F" }
        return "0"
    }

    public func run(arg: String, onComplete: (String) -> Unit):Unit{
        let parts = arg.split(",")
        if (parts.size != 3) { onComplete("参数错误，请提供3个参数") }

        // --- 关键修改点：对三个参数分别进行编码 ---
        let targetDate = urlEncode(parts[0].trimAscii())
        let targetLoc = urlEncode(parts[1].trimAscii())
        let targetEvent = urlEncode(parts[2].trimAscii())

        // 1. 构建请求后端 API 的 URL
        let url = "${serverUrl}/api/v1/history?date=${targetDate}&loc=${targetLoc}&event=${targetEvent}"

        let httpRequest = createHttp()
        let counter = SyncCounter(1)

        try {
            let options = HttpRequestOptions(method: RequestMethod.Get)

            // 2. 发起 HTTP GET 请求
            httpRequest.request(url, options) { err, response =>
                try {
                    match (err) {
                        case Some(e) => onComplete("数据库请求发生错误: ${e.toString()}")
                        case None =>
                            match (response) {
                                case Some(res) =>
                                    if (res.responseCode == 200) {
                                        let rawData = match (res.result) {
                                            case HttpData.StringData(s) => s
                                            case HttpData.ArrayData(b) => String.fromUtf8(b)
                                            case _ => ""
                                        }

                                        // 3. 假设 Python 后端直接把拼好的自然语言结果返回了，我们直接拿来用
                                        if (!rawData.isEmpty()) {
                                            onComplete("${rawData}")
                                        }
                                    } else {
                                        onComplete("数据库请求失败，状态码: ${res.responseCode}")
                                    }
                                case None => ()
                            }
                    }
                } finally {
                    counter.dec() // 释放锁
                }
            }

            // 等待网络请求完成（最大等待 5 秒）
            counter.waitUntilZero(timeout: 5000 * Duration.millisecond)

        } catch (e: Exception) {
            onComplete("网络连接失败: ${e.toString()}")
        } finally {
            httpRequest.destroy()
        }
    }
}