package ohos_app_cangjie_entry

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Entry
import ohos.arkui.state_macro_manage.Component
import ohos.arkui.state_macro_manage.State
import ohos_app_cangjie_entry.agent.*
import ohos.arkui.component.common.TextAlign
import std.convert.*
import ohos.net.http.*
import ohos.arkui.state_macro_manage.r
import ohos.resource.__GenerateResource__
import ohos_app_cangjie_entry.config.REAL_SERVER_URL

// ==========================================
// 🚀 新增：高度还原图片的登录页面组件
// ==========================================
@Component
class LoginView {
    // 接收登录成功的回调
    let onLoginSuccess: () -> Unit

    @State var account: String = ""
    @State var pwd: String = ""
    @State var errorMsg: String = ""

    func build() {
        Column {
            // 1. 顶部插画区域 (可替换为你自己的本地图片 @rawfile/xxx.png)
            // Image("https://image2url.com/r2/default/images/1773234008655-15e85f85-c12b-441e-a60f-e0cba9eaee6d.jpg")
            // .width(280)
            // .height(260)
            // .margin(top: 60, bottom: 20)
            // .objectFit(ImageFit.Contain)

            //1、登录页图标显示
            Image(@r(app.media.login_logo))
                .width(380)
                .height(360)
                .margin(top: 40, bottom: 20)
                .objectFit(ImageFit.Contain)

            // 2. 标题与副标题 (完美复刻图片排版)
            Text("智能水域监管")
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor(0x222222)
                .margin(bottom: 10)

            Text("重要警报即刻送达，绝不延迟")
                .fontSize(14)
                .fontColor(0x999999)
                .margin(bottom: 20)

            // 3. 账号密码输入框
            TextInput(placeholder: "账号 ", text: this.account)
                .width(85.percent)
                .height(50)
                .backgroundColor(0xF5F6FA)
                .borderRadius(25)
                .padding(left: 20)
                .margin(bottom: 15)
                .onChange({ v: String => this.account = v })

            TextInput(placeholder: "密码 ", text: this.pwd)
                //.type(InputType.Password) // 密码黑点模式
                .width(85.percent)
                .height(50)
                .backgroundColor(0xF5F6FA)
                .borderRadius(25)
                .padding(left: 20)
                .margin(bottom: 10)
                .onChange({ v: String => this.pwd = v })

            // 错误提示预留位
            if (!this.errorMsg.isEmpty()) {
                Text(this.errorMsg).fontColor(0xFF4444).fontSize(12).margin(bottom: 10)
            } else {
                Text("").height(12).margin(bottom: 10)
            }

            // 4. 核心橙色登录按钮 (提取自你的参考图)
            Button("立 即 登 录")
                .width(85.percent)
                .height(50)
                .backgroundColor(0xFF7B32) // 活力橙色
                .fontColor(0xFFFFFF)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .borderRadius(25)
                .shadow(radius: 8.0, color: 0x44FF7B32, offsetY: 4.0)
                .onClick({ _ =>
                    // 1. 基础的判空拦截（提升用户体验）
                    if (this.account.trimAscii().isEmpty() || this.pwd.trimAscii().isEmpty()) {
                        this.errorMsg = "账号和密码不能为空"
                        return
                    }

                    this.errorMsg = "正在验证登录信息..." // 给用户一个加载反馈

                    // 2. 拼接请求后端的 URL
                    let url = "${REAL_SERVER_URL}/api/v1/login?account=${this.account}&pwd=${this.pwd}"
                    let httpRequest = createHttp()

                    try {
                        let options = HttpRequestOptions(method: RequestMethod.Get)

                        // 3. 发起异步网络请求
                        httpRequest.request(url, options) { err, response =>
                            match (err) {
                                case Some(e) => this.errorMsg = "网络连接失败，请检查后端服务"
                                case None =>
                                    match (response) {
                                        case Some(res) =>
                                            if (res.responseCode == 200) {
                                                let rawData = match (res.result) {
                                                    case HttpData.StringData(s) => s
                                                    case HttpData.ArrayData(b) => String.fromUtf8(b)
                                                    case _ => ""
                                                }

                                                // 4. 解析后端返回的校验结果
                                                if (rawData == "SUCCESS") {
                                                    this.errorMsg = ""
                                                    this.onLoginSuccess() // 放行！切换页面
                                                } else if (rawData == "FAIL:ACCOUNT_NOT_FOUND") {
                                                    this.errorMsg = "该巡检员账号不存在"
                                                } else if (rawData == "FAIL:WRONG_PASSWORD") {
                                                    this.errorMsg = "密码错误，请重新输入"
                                                } else {
                                                    this.errorMsg = "未知错误: ${rawData}"
                                                }
                                            } else {
                                                this.errorMsg = "服务器异常 (状态码: ${res.responseCode})"
                                            }
                                        case None => ()
                                    }
                            }
                            // 别忘了销毁请求，释放内存
                            httpRequest.destroy()
                        }
                    } catch (e: Exception) {
                        this.errorMsg = "请求出错: ${e.toString()}"
                        httpRequest.destroy()
                    }
                })
        }
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(0xFFFFFF)
        .alignItems(HorizontalAlign.Center)
    }
}

// ==========================================
// 🚀 主界面 (完全保留了你原有的逻辑和 UI 代码)
// ==========================================
@Entry
@Component
class EntryView {
    // 🔥 新增：登录状态控制开关
    @State var isLoggedIn: Bool = false

    @State var welcomeMsg: String = "🌊 智能水域监管智能体"
    @State var chatHistory: String = "系统已就绪，等待您的指令..."
    @State var userInput: String = ""

    // 状态：控制视频显示和播放
    @State var isVideoVisible: Bool = false
    let videoController: VideoController = VideoController()
    @State var currentVideoSrc: String = ""

    // 状态：控制报告和图表展示
    @State var isReportVisible: Bool = false
    @State var reportSummary: String = ""
    @State var chartLabels: Array<String> = []
    @State var chartValues: Array<Int64> = []
    @State var maxChartValue: Int64 = 20

    let agent: ReActAgent = ReActAgent()

    func build() {
        // 🔥 核心改动：用 if-else 控制页面跳转
        if (!this.isLoggedIn) {
            // 没登录时，展示 LoginView 组件
            LoginView(onLoginSuccess: { =>
                this.isLoggedIn = true
            })
        } else {
            // 登录成功后，展示你原本一模一样的 Stack 代码
            Stack(alignContent: Alignment.Center) {

                // 1. 底层：全屏高清网络背景图（彻底告别本地资源报错！）
                Image("https://image2url.com/r2/default/images/1773234008655-15e85f85-c12b-441e-a60f-e0cba9eaee6d.jpg")
                    .width(100.percent)
                    .height(100.percent)
                    .objectFit(ImageFit.Cover) // 保证图片铺满不拉伸

                // 2. 上层：功能区布局
                Column {
                    // 顶部标题
                    Text(this.welcomeMsg)
                        .fontSize(26)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(0x003366) // 深海蓝
                        .margin(top: 40, bottom: 20)

                    // ==========================================
                    // 💡 聊天记录面板（毛玻璃效果）
                    // ==========================================
                    Scroll {
                        Text(this.chatHistory)
                            .fontSize(15)
                            .lineHeight(24) // 增加行高，提升阅读体验
                            .fontColor(0x1A1A1A)
                            .padding(15)
                            .width(100.percent)
                    }
                    .layoutWeight(1) // 🔥 神奇属性：自动占据剩余所有高度，不再写死 300
                    .width(92.percent)
                    .backgroundColor(0xB3FFFFFF) // 背景 70% 纯白
                    .backdropBlur(25.0) // ✨ 核心：毛玻璃模糊滤镜
                    .borderRadius(16) // 圆角变大
                    .shadow(radius: 20.0, color: 0x220055FF, offsetY: 8.0) // 淡淡的蓝色阴影
                    .margin(bottom: 15)

                    // ==========================================
                    // 💡 视频播放弹窗面板（毛玻璃效果）
                    // ==========================================
                    if (this.isVideoVisible) {
                        Column {
                            Text("📹 智能去雾实时画面")
                                .fontSize(15)
                                .fontWeight(FontWeight.Bold)
                                .fontColor(0x0055CC)
                                .margin(bottom: 10)

                            Stack(alignContent: Alignment.TopEnd) {
                                Video(
                                    src: this.currentVideoSrc,
                                    controller: this.videoController
                                )
                                .width(100.percent)
                                .height(180)
                                .autoPlay(true)
                                .borderRadius(10)

                                // 悬浮关闭按钮优化
                                Button("X")
                                    .width(30)
                                    .height(30)
                                    .margin(top: 5, right: 5)
                                    .backgroundColor(0x99000000)
                                    .fontColor(0xFFFFFF)
                                    .onClick({ _ =>
                                        this.videoController.pause()
                                        this.isVideoVisible = false
                                    })
                            }
                        }
                        .width(92.percent)
                        .padding(15)
                        .backgroundColor(0xCCFFFFFF) // 背景 80% 纯白
                        .backdropBlur(30.0) // 更强的毛玻璃效果
                        .borderRadius(16)
                        .shadow(radius: 15.0, color: 0x22003399, offsetY: 5.0)
                        .margin(bottom: 15)
                    }

                    // ==========================================
                    // 💡 数据报告图表面板（毛玻璃效果）
                    // ==========================================
                    if (this.isReportVisible) {
                        Column {
                            Text("📊 智能水域监管数据报告")
                                .fontSize(16)
                                .fontWeight(FontWeight.Bold)
                                .fontColor(0x0055CC)
                                .margin(bottom: 10)

                            Text(this.reportSummary)
                                .fontSize(14)
                                .lineHeight(20)
                                .fontColor(0x333333)
                                .margin(bottom: 15)

                            // 条形图美化
                            ForEach(this.chartLabels, { label: String, index: Int64 =>
                                Row {
                                    Text(label).width(80).fontSize(14).fontColor(0x333333)

                                    Stack(alignContent: Alignment.Start) {
                                        // 底槽：浅蓝色
                                        Row().width(100.percent).height(12).backgroundColor(0x22007DFF).borderRadius(6)
                                        // 进度条：科技蓝，带点小阴影
                                        Row().width((this.chartValues[index] * 100 / this.maxChartValue).percent)
                                            .height(12)
                                            .backgroundColor(0x007DFF)
                                            .borderRadius(6)
                                            .shadow(radius: 5.0, color: 0x44007DFF)
                                    }.width(130).margin(left: 10, right: 10)

                                    Text("${this.chartValues[index]} 次").fontSize(14).fontColor(0x0055CC).fontWeight(FontWeight.Bold)
                                }
                                .width(100.percent)
                                .margin(bottom: 10)
                                .alignItems(VerticalAlign.Center)
                            })

                            Button("关闭报告")
                                .margin(top: 10)
                                .height(36)
                                .width(120)
                                .backgroundColor(0x1A007DFF) // 10% 透明度的蓝色背景
                                .fontColor(0x007DFF) // 蓝色文字
                                .borderRadius(18)
                                .onClick({ _ => this.isReportVisible = false })
                        }
                        .width(92.percent)
                        .padding(15)
                        .backgroundColor(0xCCFFFFFF)
                        .backdropBlur(30.0)
                        .borderRadius(16)
                        .shadow(radius: 15.0, color: 0x22003399, offsetY: 5.0)
                        .margin(bottom: 15)
                    }

                    Button("异 常 事 件 看 板")
                        .width(92.percent)
                        .height(40)
                        .margin(bottom: 10)
                        .backgroundColor(0x88007DFF)
                        .fontColor(0xFFFFFF)
                        .borderRadius(10)
                        .onClick({ _ =>
                            let router = this.getUIContext().getRouter()
                            router.pushUrl(url: "page_alert")
                        })

                    // ==========================================
                    // 💡 底部输入操控区（现代化横排布局）
                    // ==========================================
                    Row {
                        TextInput(placeholder: "输入指令，例如：生成本周监管报告", text: this.userInput)
                            .layoutWeight(1) // 占据剩余全部宽度
                            .height(48)
                            .backgroundColor(0xE6FFFFFF) // 输入框不用全透明，确保打字看得很清晰
                            .borderRadius(24)
                            .padding(left: 15)
                            .onChange({ v: String =>
                                this.userInput = v
                            })

                        Button("发送")
                            .width(75)
                            .height(48)
                            .margin(left: 10)
                            .backgroundColor(0x007DFF) // 鸿蒙标准主题蓝
                            .fontColor(0xFFFFFF)
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                            .borderRadius(24)
                            .shadow(radius: 8.0, color: 0x66007DFF, offsetY: 3.0) // 按钮自带发光效果
                            .onClick({ evt: ClickEvent =>
                                if (this.userInput.trimAscii().isEmpty()) { return }

                                let currentQuery = this.userInput
                                this.chatHistory = "🙋 用户: ${currentQuery}\n\n🤖 Agent 已启动任务..."
                                this.userInput = ""

                                this.agent.run(currentQuery, { statusMsg =>
                                    this.chatHistory += statusMsg

                                    if (statusMsg.contains("视频源:")) {
                                        let urlParts = statusMsg.split("视频源:")
                                        if (urlParts.size > 1) {
                                            let videoUrl = urlParts[1].trimAscii()
                                            this.currentVideoSrc = videoUrl
                                            this.isVideoVisible = true
                                            this.videoController.start()
                                        }
                                    }

                                    if (statusMsg.contains("[CHART_DATA]")) {
                                        let parts = statusMsg.split("[CHART_DATA]")
                                        if (parts.size > 1) {
                                            this.reportSummary = parts[0].trimAscii()
                                            let rawData = parts[1].trimAscii()

                                            let pairs = rawData.split(",")
                                            var tempLabels = Array<String>(pairs.size, { _ => "" })
                                            var tempValues = Array<Int64>(pairs.size, { _ => 0 })
                                            var maxVal: Int64 = 1

                                            var i: Int64 = 0

                                            while (i < pairs.size) {
                                                let kv = pairs[i].split(":")
                                                if (kv.size == 2) {
                                                    tempLabels[i] = kv[0]
                                                    let v = Int64.parse(kv[1].trimAscii())
                                                    tempValues[i] = v
                                                    if (v > maxVal) { maxVal = v }
                                                }
                                                i += 1
                                            }

                                            this.chartLabels = tempLabels
                                            this.chartValues = tempValues
                                            this.maxChartValue = maxVal
                                            this.isReportVisible = true
                                        }
                                    }
                                })
                            })
                    }
                    .width(92.percent)
                    .margin(bottom: 25) // 距离屏幕底部留点呼吸空间
                    .alignItems(VerticalAlign.Center)
                }
                .width(100.percent)
                .height(100.percent)
                .justifyContent(FlexAlign.Start)
                .alignItems(HorizontalAlign.Center)
            }
            .width(100.percent)
            .height(100.percent)
        }
    }
}