package ohos_app_cangjie_entry.agent

import std.collection.*
import ohos.net.http.*
import ohos.base.*
import stdx.encoding.json.*

public class SimpleLLM {
    // 这里的 API Key 格式正确：id.secret
    private let apiKey: String = "107f4dd0518c45d687363bba43b19443.if5Cdg4BCugtCty3"
    private let url: String = "https://open.bigmodel.cn/api/paas/v4/chat/completions"

    public func testChat(userInput: String, onResult: (String) -> Unit): Unit {
        // 1. 创建请求实例 (建议使用 Http. 显式调用)
        let httpRequest = createHttp()
        let options = HttpRequestOptions()
        options.method = RequestMethod.Post

        // 2. 根据指导要求：完善请求头
        let headers = HashMap<String, String>()
        headers["Content-Type"] = "application/json"
        headers["Authorization"] = "Bearer ${apiKey}" // 注意 Bearer 后面有一个空格
        options.header = headers

        // 3. 根据指导要求：构建 JSON 请求体
        // 按照你的示例，model 使用 "glm-5"
        let safeInput = userInput.replace("\n", "\\n").replace("\"", "\\\"")
        let jsonBody = "{" +
            "\"model\": \"glm-5\"," +
            "\"messages\": [{\"role\": \"user\", \"content\": \"${safeInput}\"}]," +
            "\"temperature\": 0.7" + // 默认推荐值
        "}"

        options.extraData = HttpData.StringData(jsonBody)
        options.expectDataType = HttpDataType.StringValue

        // 4. 发起异步请求
        httpRequest.request(url, options, { err, response =>
            if (err.isNone()) {
                let resp = response.getOrThrow()

                // 处理 HttpData 枚举，提取响应文本
                let responseBody = match (resp.result) {
                    case HttpData.StringData(s) => s
                    case _ => ""
                }

                if (resp.responseCode == 200) {
                    try {
                        let rootNode = JsonValue.fromStr(responseBody).asObject()
                        let choices = rootNode.get("choices").getOrThrow().asArray()

                        if (choices.size() > 0) {
                            let firstChoice = choices.get(0).getOrThrow().asObject()
                            let message = firstChoice.get("message").getOrThrow().asObject()
                            let content = message.get("content").getOrThrow().asString()

                            // 成功拿到 AI 回复
                            onResult(content.getValue())
                        } else {
                            onResult("API 返回成功但 choices 为空")
                        }
                    } catch (e: Exception) {
                        onResult("JSON 解析失败: ${responseBody}")
                    }
                } else {
                    // 如果 Code 不是 200，responseBody 通常包含错误信息（如认证失败原因）
                    onResult("API 报错码: ${resp.responseCode}, 详情: ${responseBody}")
                }
            } else {
                let errorInfo = err.getOrThrow()
                onResult("网络链路错误: ${errorInfo.code}")
            }

            // 必须销毁请求实例释放资源
            httpRequest.destroy()
        })
    }
}