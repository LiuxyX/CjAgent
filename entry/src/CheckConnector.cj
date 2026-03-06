/**
 * Created on 2026/3/6
 */
package ohos_app_cangjie_entry
import agent_vision_connector.*

main() {
    println("--- 开始第三方库 AgentVisionConnector 联调检查 ---")

    let visionClient = VisionClient("http://127.0.0.1:8000")

    // 🔥 这里的 rawJson 是你的 Python 后端真实返回的数据格式
    // 在你们的正式项目中，队友会用他们配置好网络环境的代码执行 http 请求拿到这串字符，然后传给你的库
    let rawJson = "{\"isFoggy\": true, \"detectedTargets\": [\"person\", \"boat\"], \"errorMessage\": \"\"}"

    println("主程序从 ${visionClient.getServerUrl()} 获取到了底层数据...")

    // 调用库中的核心解析方法
    let result = visionClient.parseVisionAnalysis(rawJson)

    // 验证返回结果 (你的代码逻辑完美，原样保留)
    if (result.errorMessage == "") {
        println("✅ 库调用成功！")
        println("   - 是否检测到雾气: ${result.isFoggy}")
        println("   - 识别到的目标列表: ${result.detectedTargets}")

        if (result.detectedTargets.size > 0) {
            println("   - AI 识别详情: 已发现 ${result.detectedTargets.size} 类目标。")
        }
    } else {
        println("❌ 库调用失败，错误详情: ${result.errorMessage}")
    }

    println("--- 检查结束 ---")
}