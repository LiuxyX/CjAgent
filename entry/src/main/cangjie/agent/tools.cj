/**
 * Created on 2026/3/3
 */
package ohos_app_cangjie_entry.agent


// 工具接口
public interface Tool {
    func getName(): String
    func desc(): String
    func run(arg: String): String
}

// 模拟天气工具
public class WeatherTool <: Tool {
    public func getName() { "get_weather" }
    public func desc() { "查询指定城市的天气。参数：城市名" }
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