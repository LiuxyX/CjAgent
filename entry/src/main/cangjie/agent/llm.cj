/**
 * Created on 2026/3/3
 */
package ohos_app_cangjie_entry.agent

public class LLMClient {
    // 实际开发时，这里应使用仓颉的 HttpClient 发起 POST 请求
    func chat(prompt: String): String {
        // 模拟 LLM 的 ReAct 输出格式

        // 如果 prompt 里已经包含了 Observation（说明工具已经跑完了）
        if (prompt.contains("Observation:")) {
            return "Final Answer: 根据工具返回的结果，北京天气晴朗，气温 25°C。"
        }

        // 如果只是初始请求
        if (prompt.contains("Thought")) {
            return "Thought: 我需要先查询北京的天气。\nAction: get_weather(\"北京\")"
        }

        return "Final Answer: 根据查询，北京天气晴朗。"
    }
}