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

    // 新增状态：控制视频显示和播放
    @State var isVideoVisible: Bool = false
    let videoController: VideoController = VideoController()

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

            // 2. 🔥 新增：视频播放弹窗逻辑
            if (this.isVideoVisible) {
                Column {
                    Text("📹 智能去雾监控画面")
                        .fontSize(14)
                        .margin(bottom: 5)
                        .fontColor(0x333333)

                    Stack(alignContent: Alignment.TopEnd) {
                        Video(
                            src: "@rawfile/test.mp4",
                            controller: this.videoController
                        )
                        .width(100.percent)
                        .height(200)
                        .autoPlay(true)
                        .borderRadius(8)
                        // 关闭按钮
                        Button("X")
                            .width(30)
                            .height(30)
                            .backgroundColor(0xCC000000)
                            .onClick({ _ =>
                                this.videoController.pause()
                                this.isVideoVisible = false
                            })
                    }
                }
                .width(90.percent)
                .margin(top: 15)
                .padding(10)
                .backgroundColor(0xFFFFFF)
                .borderRadius(12)
                .shadow(radius: 10.0, color: 0x22000000)
            }

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

//                    // 【核心修改】：状态接收改为追加 +=
//                    this.agent.run(currentQuery, { statusMsg =>
//                        this.chatHistory += statusMsg
//                    })
                    this.agent.run(currentQuery, { statusMsg =>
                        // 追加状态信息
                        this.chatHistory += statusMsg

                        // 拦截信号：如果发现去雾成功的关键词，立刻拉起视频
                        if (statusMsg.contains("已触发视频去雾增强播放")) {
                            this.isVideoVisible = true
                            // 稍微延迟让组件挂载
                            this.videoController.start()
                        }
                    })
                })
        }
        .width(100.percent)
        .height(100.percent)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
    }
}