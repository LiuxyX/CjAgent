package ohos_app_cangjie_entry

import kit.ArkUI.* // 导入基础组件
import ohos.arkui.state_macro_manage.Entry
import ohos.arkui.state_macro_manage.Component
import ohos.arkui.state_macro_manage.State
import ohos_app_cangjie_entry.agent.*
import ohos.arkui.component.common.TextAlign

@Entry
@Component
class EntryView {
    // 1. 状态变量管理
    @State var welcomeMsg: String = "欢迎使用仓颉智能助手！"
    @State var chatHistory: String = "等待提问..."
    @State var userInput: String = "" // 存储输入框的文字

    // 2. 实例化 Agent
    let agent: ReActAgent = ReActAgent()

    func build() {
        // 使用 Column 纵向布局
        Column {
            // 欢迎语
            Text(this.welcomeMsg)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .margin(top: 30, bottom: 20)

            // 结果显示区（聊天框）
            Scroll {
                Text(this.chatHistory)
                    .fontSize(18)
                    .padding(15)
                    .width(100.percent)
            }
            .width(90.percent)
            .height(200)
            .backgroundColor(0xF2F2F2) // 浅灰色背景
            .borderRadius(10)

            // 3. 输入框：绑定 userInput
            TextInput(placeholder: "请输入您的问题...", text: this.userInput)
                .width(90.percent)
                .height(45)
                .margin(top: 20)
                .onChange({ v: String =>
                    this.userInput = v // 用户打字时更新变量
                })

            // 4. 发送按钮
            Button("询问 Agent")
                .width(150)
                .height(45)
                .margin(top: 20)
                .onClick({ evt: ClickEvent =>
                    if (this.userInput.trimAscii().isEmpty()) {
                        return
                    }

                    this.chatHistory = "Agent 正在思考中..."

                    // 执行 Agent 逻辑
                    let response = this.agent.run(this.userInput)

                    // 显示结果并清空输入框
                    this.chatHistory = "用户: ${this.userInput}\n\n结果: ${response}"
                    this.userInput = ""
                })
        }
        .width(100.percent)
        .height(100.percent)
        .justifyContent(FlexAlign.Start) // 顶部对齐
        .alignItems(HorizontalAlign.Center) // 水平居中
    }
}