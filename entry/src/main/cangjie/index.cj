package ohos_app_cangjie_entry

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Entry
import ohos.arkui.state_macro_manage.Component
import ohos.arkui.state_macro_manage.State
import ohos_app_cangjie_entry.agent.*
import ohos.arkui.component.common.TextAlign

@Entry
@Component
class EntryView {
    @State var welcomeMsg: String = "欢迎使用仓颉智能助手！"
    @State var chatHistory: String = "等待提问..."
    @State var userInput: String = ""

    let agent: ReActAgent = ReActAgent()

    func build() {
        Column {
            Text(this.welcomeMsg)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .margin(top: 30, bottom: 20)

            Scroll {
                Text(this.chatHistory)
                    .fontSize(16) // 稍微调小一点字体，方便看思考过程
                    .padding(15)
                    .width(100.percent)
            }
            .width(90.percent)
            .height(300) // 增高聊天框以容纳多行思考过程
            .backgroundColor(0xF2F2F2)
            .borderRadius(10)

            TextInput(placeholder: "请输入您的问题（例：查询北京天气）", text: this.userInput)
                .width(90.percent)
                .height(45)
                .margin(top: 20)
                .onChange({ v: String =>
                    this.userInput = v
                })

            Button("询问 Agent")
                .margin(top: 15)
                .onClick({ evt: ClickEvent =>
                    if (this.userInput.trimAscii().isEmpty()) { return }

                    let currentQuery = this.userInput
                    // 初始化聊天框，准备迎接流式状态推送
                    this.chatHistory = "🙋 用户: ${currentQuery}\n\n🤖 Agent 已启动任务..."
                    this.userInput = ""

                    // 【核心修改】：状态接收改为追加 +=
                    this.agent.run(currentQuery, { statusMsg =>
                        this.chatHistory += statusMsg
                    })
                })
        }
        .width(100.percent)
        .height(100.percent)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
    }
}