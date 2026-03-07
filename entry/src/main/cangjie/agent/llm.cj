//llm。cj文件
package ohos_app_cangjie_entry.agent

import std.collection.*
import ohos.net.http.*
import ohos.base.*


/*
输入：prompt ——String  提示词+用户的问题
输出：ai的回复——String

*/

import stdx.encoding.json.*


public class LLMClient {
    private let apiKey: String = "107f4dd0518c45d687363bba43b19443.if5Cdg4BCugtCty3"
    private let url: String = "https://open.bigmodel.cn/api/paas/v4/chat/completions"

    public func chat(prompt: String, onResult: (String) -> Unit): Unit {
        let httpRequest = createHttp()
        let options = HttpRequestOptions()

        options.method = RequestMethod.Post

        let headers = HashMap<String, String>()
        headers["Content-Type"] = "application/json"
        headers["Authorization"] = "Bearer ${apiKey}"
        options.header = headers

        // 【核心修改】：处理 Prompt 中的换行符和双引号，防止 JSON 拼接导致 400 报错
        let safePrompt = prompt.replace("\\", "\\\\")
                               .replace("\"", "\\\"")
                               .replace("\n", "\\n")
                               .replace("\r", "")
        let jsonStr = "{\"model\": \"glm-5\", \"messages\": [{\"role\": \"user\", \"content\": \"${safePrompt}\"}]}"

        options.extraData = HttpData.StringData(jsonStr)
        options.expectDataType = HttpDataType.StringValue

        // 异步请求
        httpRequest.request(url, options, { err, response =>
            if (err.isNone()) {
                let resp = response.getOrThrow()

                match (resp.result) {
                    case HttpData.StringData(resStr) =>
                        // 2. 将原本直接返回 resStr 的地方，替换为 JSON 解析逻辑
                        try {
                            // 将原始字符串解析为 JSON 节点
                            let rootNode = JsonValue.fromStr(resStr).asObject()

                            // 逐层剥洋葱：choices -> [0] -> message -> content
                            let choicesArray = rootNode.get("choices").getOrThrow().asArray()

                            if (choicesArray.size() > 0) {
                                let firstChoice = choicesArray.get(0).getOrThrow().asObject()
                                let messageObj = firstChoice.get("message").getOrThrow().asObject()
                                let content = messageObj.get("content").getOrThrow().asString()

                                // 成功提取纯净的回答文本！
                                // 注意：不同版本的仓颉 SDK 中 asString() 可能返回 String
                                // 或 JsonString 对象 (此时需调 .getValue() )，视你 IDE 提示为准
                                onResult(content.getValue())
                            } else {
                                onResult("Error: 服务器返回的内容为空 (choices 为空)")
                            }
                        } catch (e: Exception) {
                            // 解析失败的兜底机制：把原始报文弹出来，方便咱们排查问题（比如 token 欠费导致的报错 JSON）
                            onResult("JSON 解析失败。原始返回: ${resStr}")
                        }

                    case _ =>
                        onResult("Error: Unexpected data type")
                }
            } else {
                let errorInfo = err.getOrThrow()
                onResult("Error Code: ${errorInfo.code}")
            }

            // 别忘了销毁请求
            httpRequest.destroy()
        })
    }
}