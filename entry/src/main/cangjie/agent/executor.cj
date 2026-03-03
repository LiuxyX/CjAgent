/**
 * Created on 2026/3/3
 */
package ohos_app_cangjie_entry.agent
import std.collection.*

public class ReActAgent {
    let tools = HashMap<String, Tool>()
    let llm = LLMClient()

    public init() {
        let w = WeatherTool()
        let k = WikiTool()
        tools[w.getName()] = w
        tools[k.getName()] = k
    }

    public func run(query: String): String {
        var fullPrompt = "你是一个智能助手。你可以使用以下工具：\n"
        for ((name, tool) in tools) {
            fullPrompt += "${name}: ${tool.desc()}\n"
        }
        fullPrompt += "回答格式：\nThought: 思考过程\nAction: 工具名(\"参数\")\nObservation: 工具结果\n... (重复)\nFinal Answer: 最终答案\n\n用户问题: ${query}"

        // 简化版的执行循环（实际需解析正则）
        let response = llm.chat(fullPrompt)  //拼接好后发送给llm.chat
              //response=“ Thought: 我需要先查询北京的天气。Action: get_weather(\"北京\") ”

        //收到回复之后，调用对应的工具函数
        if (response.contains("Action:")) {
            // 模拟解析过程：提取 get_weather 和 "北京"
               //执行工具函数
            let toolResult = tools.get("get_weather").getOrThrow().run("北京")
            //toolResult=当前天气：晴，25°C

            //获取最终答案
            let finalPrompt = "${fullPrompt}\n${response}\nObservation: ${toolResult}"
            //再次调用llm，获取最终答案
            return llm.chat(finalPrompt)
        }

        return response
    }
}
