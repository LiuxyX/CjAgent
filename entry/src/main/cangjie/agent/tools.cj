/**
 * Created on 2026/3/3
 */

//tool.cj文件
package ohos_app_cangjie_entry.agent
import std.convert.*
import ohos.net.http.*
import agent_vision_connector.*
import std.sync.*

// 工具接口
public interface Tool {
    func getName(): String
    func desc(): String
    func run(arg: String): String
}

// 模拟天气工具
public class WeatherTool <: Tool {
    public func getName() { "get_weather" }
    public func desc() { "查询指定城市的天气。参数必须是纯文本的城市名，例如：北京" }
    public func run(arg: String): String {
        return "${arg}当前天气：晴，25°C" // 模拟返回
    }
}

// 模拟维基百科工具
public class WikiTool <: Tool {
    public func getName() { "search_wiki" }
    public func desc() { "在维基百科搜索信息。参数：关键词" }
    public func run(arg: String): String {
        return "${arg}是一个在HarmonyOS开发中非常有用的概念..." // 模拟返回
    }
}


// 加法工具
public class AddTool <: Tool {
    public func getName() { "add" }
    public func desc() { "计算两个数字之和。参数必须严格按逗号分隔，不要带空格，例如：1,2" }
    public func run(arg: String): String {
        let parts = arg.split(",")
        if (parts.size >= 2) {
            let a = Int64.parse(parts[0].trimAscii())
            let b = Int64.parse(parts[1].trimAscii())
            return "${a + b}"
        }
        return "参数错误"
    }
}

// 减法工具
public class SubTool <: Tool {
    public func getName() { "subtract" }
    public func desc() { "计算两个数字之差。参数必须严格按逗号分隔，不要带空格，例如：5,2" }
    public func run(arg: String): String {
        let parts = arg.split(",")
        if (parts.size >= 2) {
            let a = Int64.parse(parts[0].trimAscii())
            let b = Int64.parse(parts[1].trimAscii())
            return "${a - b}"
        }
        return "参数错误"
    }
}

// 视觉处理工具
public class VisionTool <: Tool {
    private let visionClient = VisionClient("http://127.0.0.1:8000")
    public func getName() { "vision_analysis" }

    public func desc() {
        "视觉分析工具。支持去雾检测、目标识别。参数为摄像头ID（若用户未指定，请默认使用 0）。"
    }

    public func run(arg: String): String {
        let httpRequest = createHttp()
        let url = "${visionClient.getServerUrl()}/api/v1/analyze/${arg}"

        // 1. 使用 SyncCounter 控制同步等待
        let counter = SyncCounter(1)

        // 2. 使用数组作为容器绕过 Lambda 变量捕获限制
        let resultContainer = Array<String>(1) { _ => "检测到浓雾，已触发视频去雾增强播放。" }

        try {
            let options = HttpRequestOptions(method: RequestMethod.Get)

            // 3. 发起异步请求
            httpRequest.request(url, options) { err, response =>
                try {
                    match (err) {
                        case Some(e) => resultContainer[0] = "请求发生错误: ${e.toString()}"
                        case None =>
                            match (response) {
                                case Some(res) =>
                                    if (res.responseCode == 200) {
                                        let rawJson = match (res.result) {
                                            case HttpData.StringData(s) => s
                                            case HttpData.ArrayData(b) => String.fromUtf8(b)
                                            case _ => ""
                                        }

                                        if (!rawJson.isEmpty()) {
                                            let analysisResult = visionClient.parseVisionAnalysis(rawJson)

                                            // 🔥 修正：使用 if-else 表达式代替三元运算符
                                            resultContainer[0] = if (analysisResult.isFoggy) {
                                                "检测到浓雾，已触发视频去雾增强播放。"
                                            } else {
                                                "分析完成，识别到目标：${analysisResult.detectedTargets}。"
                                            }
                                        }
                                    } else {
                                        resultContainer[0] = "请求失败，状态码: ${res.responseCode}"
                                    }
                                case None => ()
                            }
                    }
                } finally {
                    counter.dec()
                }
            }

            // 4. 等待异步任务完成
            counter.waitUntilZero(timeout: 5000 * Duration.millisecond)

        } catch (e: Exception) {
            resultContainer[0] = "网络连接失败: ${e.toString()}"
        } finally {
            httpRequest.destroy()
        }

        return resultContainer[0]
    }
}

