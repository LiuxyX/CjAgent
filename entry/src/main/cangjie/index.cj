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
    @State var welcomeMsg: String = "仓颉智能助手 & 视频播放"
    @State var chatHistory: String = "等待提问..."
    @State var userInput: String = ""

    // 1. 定义视频控制器
    let videoController: VideoController = VideoController()

    // 2. 引用本地资源 (确保 resources/rawfile 下有 demo.mp4)
    // 注意：仓颉中引用 rawfile 不需要写文件后缀名
    @State var videoPath: String = "rawfile/demo.mp4"


    let agent: ReActAgent = ReActAgent()

    func build() {
        Column {
            // 标题
            Text(this.welcomeMsg)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .margin(top: 20, bottom: 10)

            // --- 视频播放区域 ---
         Video(
                src: this.videoPath, // 直接传字符串路径
                controller: this.videoController
            )
            .width(90.percent)
            .height(200)
            .autoPlay(true)
            .controls(true)


                .objectFit(ImageFit.Contain)
                .backgroundColor(Color.Black)
                .borderRadius(10)

            // --- 聊天历史区域 ---
            Scroll {
                Text(this.chatHistory)
                    .fontSize(14)
                    .padding(15)
                    .width(100.percent)
            }
            .width(90.percent)
            .layoutWeight(1) // 自动分配剩余空间
            .margin(top: 15)
            .backgroundColor(0xF2F2F2)
            .borderRadius(10)

            // --- 输入与交互区域 ---
            TextInput(placeholder: "请输入问题...", text: this.userInput)
                .width(90.percent)
                .height(40)
                .margin(top: 10)
                .onChange({ v: String =>
                    this.userInput = v
                })

            Button("询问 Agent")
                .width(90.percent)
                .margin(top: 10, bottom: 20)
                .onClick({ evt: ClickEvent =>
                    if (this.userInput.trimAscii().isEmpty()) { return }
                    let currentQuery = this.userInput
                    this.chatHistory = "🙋 用户: ${currentQuery}\n\n🤖 Agent 思考中..."
                    this.userInput = ""

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