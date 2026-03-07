/**
 * Created on 2026/3/3
 */

//tool.cj文件
package ohos_app_cangjie_entry.agent
import std.convert.*

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


