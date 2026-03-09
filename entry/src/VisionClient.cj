package agent_vision_connector

import std.collection.*

public class VisionResult {
    public let isFoggy: Bool
    public let detectedTargets: Array<String>
    public let errorMessage: String

    // 🔥 构造重载 1：正常情况，不需要传错误信息
    public init(isFoggy: Bool, targets: Array<String>) {
        this.isFoggy = isFoggy
        this.detectedTargets = targets
        this.errorMessage = ""
    }

    // 🔥 构造重载 2：出现异常时，允许传入错误信息
    public init(isFoggy: Bool, targets: Array<String>, err: String) {
        this.isFoggy = isFoggy
        this.detectedTargets = targets
        this.errorMessage = err
    }
}

public class VisionClient {
    private let serverUrl: String

    // 🔥 构造重载 1：队友如果不传 IP，默认使用本地 8000 端口
    public init() {
        this.serverUrl = "http://127.0.0.1:8000"
    }

    // 🔥 构造重载 2：队友可以自己传入 Python 服务器的 IP
    public init(serverUrl: String) {
        this.serverUrl = serverUrl
    }

    public func getServerUrl(): String {
        return this.serverUrl
    }

    // 纯逻辑的视觉数据解析引擎
    // 纯逻辑的视觉数据解析引擎
    public func parseVisionAnalysis(rawJsonData: String): VisionResult {

        let foggy = rawJsonData.contains("\"isFoggy\": true") || rawJsonData.contains("\"isFoggy\":true")

        let hasPerson = rawJsonData.contains("\"person\"")
        let hasBoat = rawJsonData.contains("\"boat\"")
        let hasBottle = rawJsonData.contains("\"plastic_bottle\"")

        // 🔥 终极防报错解法：使用原生数组字面量，彻底抛弃 ArrayList！
        var targets: Array<String>

        // 针对目前 V1.0 版本的 3 种识别目标，直接进行数组拼装，绕开所有 API 限制
        if (hasPerson && hasBoat && hasBottle) {
            targets = ["person", "boat", "plastic_bottle"]
        } else if (hasPerson && hasBoat) {
            targets = ["person", "boat"]
        } else if (hasPerson && hasBottle) {
            targets = ["person", "plastic_bottle"]
        } else if (hasBoat && hasBottle) {
            targets = ["boat", "plastic_bottle"]
        } else if (hasPerson) {
            targets = ["person"]
        } else if (hasBoat) {
            targets = ["boat"]
        } else if (hasBottle) {
            targets = ["plastic_bottle"]
        } else {
            targets = [] // 空数组
        }

        var errMsg = ""
        if (rawJsonData.contains("\"errorMessage\": \"\"") == false && rawJsonData.contains("\"errorMessage\":\"\"") == false) {
            errMsg = "接收到异常数据或解析失败"
        }

        return VisionResult(foggy, targets, errMsg)
    }
}