package ohos_app_cangjie_entry.agent
import std.collection.*
import std.time.DateTime

public class ReActAgent {
    let tools = HashMap<String, Tool>()
    let llm = LLMClient()
    // 设置最大循环次数，防止 Agent 陷入死循环
    let MAX_STEPS: Int64 = 5 


// 把类似这样的参数调大

public init() {

        let v = VisionTool()
        tools[v.getName()] = v

        let h = HistoryQueryTool()
        let d = DeviceStatusTool()
        let r = ReportTool()

        tools[h.getName()] = h
        tools[d.getName()] = d
        tools[r.getName()] = r
    }

    public func run(query: String, onStatusUpdate: (String) -> Unit): Unit {
        // 获取当前真实的系统时间
        let nowStr = DateTime.now().toString()
        // 2. 按 "T" 切割，安全提取日期和时间
        let parts = nowStr.split("T")
        let todayStr = parts[0] // 拿到 "2026-03-11"
        let timeStr = parts[1].split(".")[0] // 拿到 "15:30:00"，去掉了毫秒尾巴


        var systemPrompt = "你是一个水域监管智能助手。\n"
        systemPrompt += "【重要时间基准】：今天是 ${todayStr}，当前时间是 ${timeStr}。当用户提到“今天”、“昨天”、“去年同期”等时间词汇时，必须以此时间为基准进行严密推算。\n\n"

        systemPrompt += "你可以使用以下工具：\n"
        for ((_, tool) in tools) {
            systemPrompt += "- ${tool.getName()}: ${tool.desc()}\n"
        }

        systemPrompt += "\n当前你需要解决的任务: ${query}\n"
        systemPrompt += "\n必须严格遵守以下格式回答：\n"
        systemPrompt += "Thought: 你的思考过程\n"
        systemPrompt += "1. 每次回答必须包含 'Thought'，说明你的分析过程。\n"
        systemPrompt += "2. 如果需要使用工具，请输出 'Action: 工具名(参数)'。一次只能输出一个 Action，参数不要加引号。\n"
        systemPrompt += "3. 如果已有信息不足以回答问题，请通过 Action 调用工具获取更多信息，此时【严禁】输出 'Final Answer'。\n"
        systemPrompt += "4. 只有当你获得了足够的观察结果并能直接回答用户时，才输出 'Final Answer: 最终给用户的回复'，此时【严禁】输出 'Action'。\n"

        // 启动思考循环，初始 step 为 0
        step(systemPrompt, 0, onStatusUpdate)
    }

    private func step(currentPrompt: String, stepCount: Int64, onStatusUpdate: (String) -> Unit): Unit {
        if (stepCount >= MAX_STEPS) {
            onStatusUpdate("\n⚠️ 思考轮数达到上限，强制终止。")
            return
        }

        llm.chat(currentPrompt, { response =>
            // 1. 提取并展示思考过程 (Thought)
            let thought = extractValue(response, "Thought:")
            if (thought.size > 0) {
                onStatusUpdate("\n🤔 思考: ${thought}")
            }

            // 2. 路由：调用工具 或 给出最终答案
            if (response.contains("Action:")) {
                executeTool(response, currentPrompt, stepCount, onStatusUpdate)
            } else if (response.contains("Final Answer:")) {
                let finalAns = extractValue(response, "Final Answer:")
                onStatusUpdate("\n✅ 最终答案: \n${finalAns}")
            }
            else {
                onStatusUpdate("\n⚠️ 模型未按格式输出，原始回复: \n${response}")
            }
        })
    }

    private func executeTool(llmResponse: String, oldPrompt: String, stepCount: Int64, onStatusUpdate: (String) -> Unit) {
        try {
            let actionStr = extractValue(llmResponse, "Action:") 
            let parts = actionStr.split("(")
            if (parts.size < 2) { throw Exception("Action 格式异常") }

            let toolName = parts[0].trimAscii()
            var arg = parts[1]
            // 【核心修改】：暴力去除多余的右括号和双引号，极大提升解析容错率
            arg = arg.replace(")", "").replace("\"", "").trimAscii()

            // 展示调用动作
            onStatusUpdate("\n🛠️ 调用工具: [${toolName}], 参数: [${arg}]")

            match (tools.get(toolName)) {
                case Some(tool) =>
                    // 🔥 修改：使用异步回调的方式接收 observation 观察结果
                    tool.run(arg, { observation =>
                        // 展示观察结果
                        onStatusUpdate("\n🔍 观察结果: ${observation}")

                        // 将结果喂回给 LLM，递归调用 step
                        let nextPrompt = "${oldPrompt}\n${llmResponse}\nObservation: ${observation}\n"
                        step(nextPrompt, stepCount + 1, onStatusUpdate)
                    })

                case None =>
                    let errorMsg = "找不到指定的工具：${toolName}"
                    onStatusUpdate("\n❌ ${errorMsg}")
                    let nextPrompt = "${oldPrompt}\n${llmResponse}\nObservation: ${errorMsg}\n"
                    step(nextPrompt, stepCount + 1, onStatusUpdate)
            }
        } catch (e: Exception) {
            onStatusUpdate("\n❌ 解析工具调用失败，终止本次思考。")
        }
    }

    private func extractValue(text: String, key: String): String {
        let index = text.indexOf(key).getOrDefault({ => -1 })
        if (index == -1) { return "" }

        let start = index + key.size
        let content = text[start..text.size]

        // 🚀 核心修复：如果是提取最终答案，直接返回后面的【所有多行内容】
        if (key == "Final Answer:") {
            return content.trimAscii()
        }

        // 对于 Thought 和 Action，由于它们可能会和其它内容连在一起，保留单行切割机制
        return content.split("\n")[0].trimAscii()
    }
}




