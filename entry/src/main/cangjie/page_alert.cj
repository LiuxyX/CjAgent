package ohos_app_cangjie_entry

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Entry
import ohos.arkui.state_macro_manage.Component
import ohos.arkui.state_macro_manage.*
import ohos.net.http.*
import std.time.*
import ohos_app_cangjie_entry.config.MOCK_SERVER_URL


@Entry
@Component
class page_alert {
    @State var statusTitle: String = "📡 系统状态：巡检中"
    @State var detailMsg: String = "正在检索实时画面..."
    @State var videoUrl: String = ""
    @State var isAlerting: Bool = false
    @State var alertHistory: Array<String> = []
    @State var currentDate: String = "" // 用于存放实时日期

    let vController: VideoController = VideoController()

    public func aboutToAppear() {
        let dt = DateTime.now()
        this.currentDate = "${dt.year}-${dt.month}-${dt.dayOfMonth}" // 初始化日期
        this.doUpdate()
    }

    public func doUpdate(): Unit {
        let httpRequest = createHttp()
        let url =  MOCK_SERVER_URL + "/api/v1/status/test"

        try {
            let options = HttpRequestOptions(method: RequestMethod.Get)
            httpRequest.request(url, options) { err, response =>
                match (err) {
                    case None =>
                        match (response) {
                            case Some(res) =>
                                if (res.responseCode == 200) {
                                    let rawData = match (res.result) {
                                        case HttpData.StringData(s) => s
                                        case HttpData.ArrayData(b) => String.fromUtf8(b)
                                        case _ => ""
                                    }
                                    this.handleJsonResult(rawData)
                                }
                            case None => ()
                        }
                    case _ => this.statusTitle = "网络连接异常"
                }
                httpRequest.destroy()
                this.scheduleNextUpdate()
            }
        } catch (e: Exception) {
            httpRequest.destroy()
            this.scheduleNextUpdate()
        }
    }

    public func scheduleNextUpdate(): Unit {
        spawn {
            sleep(Duration.millisecond * 2000)
            this.doUpdate()
        }
    }

    public func handleJsonResult(json: String): Unit {
        let newIsAlerting = json.contains("\"hasIllegalBehavior\":true")

        // 【关键逻辑】：只有当 状态真的发生了变化 时才进入
        if (newIsAlerting != this.isAlerting) {

            if (newIsAlerting == true) {
                // --- 触发警报的瞬间 ---

                // 1. 立即更新状态，防止异步请求再次进入该判断
                this.isAlerting = true

                // 2. 生成日志记录
                var behavior = ""
                if (json.contains("涉水违规")) { behavior = "涉水违规" }
                else if (json.contains("非法捕捞")) { behavior = "非法捕捞" }
                else if (json.contains("水面垃圾")) { behavior = "水面垃圾" }
                else { behavior = "违规漂浮" }

                // ✨【关键新增】：手动解析 location 字段
                var loc = "未知河段"
                let locKey = "\"location\":\""
                match (json.indexOf(locKey)) {
                    case Some(startIdx) =>
                        let realStart = startIdx + locKey.size
                        let tempStr = json[realStart..]
                        match (tempStr.indexOf("\"")) {
                            case Some(endIdx) => loc = tempStr[0..endIdx]
                            case None => ()
                        }
                    case None => ()
                }

                let dt = DateTime.now()
                let h = if(dt.hour < 10) { "0${dt.hour}" } else { "${dt.hour}" }
                let m = if(dt.minute < 10) { "0${dt.minute}" } else { "${dt.minute}" }
                let s = if(dt.second < 10) { "0${dt.second}" } else { "${dt.second}" }
                let nowTime = "${h}:${m}:${s}"

                let record = "[${nowTime}] ${loc}：${behavior}"

                // 3. 写入数组
                let newSize = this.alertHistory.size + 1
                let newHistory = Array<String>(newSize, { i =>
                    if (i == 0) { record } else { this.alertHistory[i - 1] }
                })
                this.alertHistory = if (newSize > 10) { newHistory[0..10] } else { newHistory }

                // 4. 解析视频
                let key = "\"videoUrl\":\""
                match (json.indexOf(key)) {
                    case Some(startIdx) =>
                        let realStart = startIdx + key.size
                        let tempStr = json[realStart..]
                        match (tempStr.indexOf("\"")) {
                            case Some(endIdx) => this.videoUrl = tempStr[0..endIdx]
                            case None => ()
                        }
                    case None => ()
                }

            } else {
                // --- 警报解除的瞬间 ---
                this.isAlerting = false
                this.videoUrl = ""
                this.vController.pause()
            }
        }

        // 实时更新卡片文字（这部分可以每 2 秒跑一次）
        if (this.isAlerting) {
            this.statusTitle = "🚨 实时警报：检测到异常"
            this.detailMsg = "提醒：发现人员违法行为，请立即处理"
        } else {
            this.statusTitle = "✅ 系统状态：巡检正常"
            this.detailMsg = "画面解析中，暂无安全隐患"
        }
    }

    public func build() {
        Stack(alignContent: Alignment.Top) {
            // 1. 背景图
            Image("https://image2url.com/r2/default/images/1773234008655-15e85f85-c12b-441e-a60f-e0cba9eaee6d.jpg")
                .width(100.percent).height(100.percent).objectFit(ImageFit.Cover).blur(5.0)

            Column {
                Text("实时水域监控终端")
                    .fontSize(24).fontWeight(FontWeight.Bold).fontColor(0x003366)
                    .margin(top: 40, bottom: 20)

                // 2. 状态卡片
                Column {
                    Text(this.statusTitle)
                        .fontSize(22).fontWeight(FontWeight.Bold)
                        .fontColor(if(this.isAlerting){ 0xD0021B } else { 0x007DFF })

                    Text(this.detailMsg)
                        .fontSize(16).margin(top: 10).fontColor(0x4A4A4A)
                }
                .width(92.percent).padding(20).backgroundColor(0xB3FFFFFF)
                .backdropBlur(25.0).borderRadius(16).margin(bottom: 20)

                // 3. 视频播放区
                Stack() {
                    if (this.videoUrl != "" && this.isAlerting) {
                        Video(src: this.videoUrl, controller: this.vController)
                            .width(100.percent).height(240).autoPlay(true).controls(false).borderRadius(12)
                    } else {
                        Column() {
                            LoadingProgress().width(40).height(40).color(0x666666).margin(bottom: 10)
                            Text("信号扫描中...").fontColor(0x666666).fontSize(14)
                        }
                        .width(100.percent).height(240).backgroundColor(0xE6000000).justifyContent(FlexAlign.Center).borderRadius(12)
                    }
                }
                .width(92.percent).height(240)
                .border(width: if(this.isAlerting) { 4 } else { 1 }, color: if(this.isAlerting) { 0xFF0000 } else { 0xB3FFFFFF })
                .borderRadius(12)

                // 4. 异常行为记录
                Column {
                    Row {
                        Text("📜").fontSize(16)
                        Text(" 异常行为记录").fontSize(14).fontWeight(FontWeight.Bold).fontColor(0x003366)
                    }.margin(bottom: 10)

                    Scroll() {
                        Column() {
                            if (this.alertHistory.size == 0) {
                                Text("暂无巡检异常").fontSize(13).fontColor(0x999999)
                            } else {
                                // 手动罗列最近的 4 条，这种写法在 1.1.0 编译器中最稳定
                                if (this.alertHistory.size > 0) {
                                    Text(this.alertHistory[0]).fontSize(13).fontColor(0xD0021B).margin(bottom: 6).width(100.percent)
                                }
                                if (this.alertHistory.size > 1) {
                                    Text(this.alertHistory[1]).fontSize(13).fontColor(0xD0021B).margin(bottom: 6).width(100.percent)
                                }
                                if (this.alertHistory.size > 2) {
                                    Text(this.alertHistory[2]).fontSize(13).fontColor(0xD0021B).margin(bottom: 6).width(100.percent)
                                }
                                if (this.alertHistory.size > 3) {
                                    Text(this.alertHistory[3]).fontSize(13).fontColor(0xD0021B).margin(bottom: 6).width(100.percent)
                                }
                            }
                        }.width(100.percent).alignItems(HorizontalAlign.Start)
                    }.height(90)
                    // ✨【右下角部分修正】：引用 this.currentDate
                    Row {
                        Text(" 📅 日期：${this.currentDate}")
                            .fontSize(10)
                            .fontColor(0x666666)
                            .opacity(0.8)
                    }
                    .width(100.percent)
                    .justifyContent(FlexAlign.End)
                    .margin(top: 5)
                }
                .width(92.percent).padding(15).margin(top: 20)
                .backgroundColor(0x99FFFFFF).backdropBlur(20.0).borderRadius(12)

                // 5. 退出按钮
                Button("暂离监控界面")
                    .width(70.percent).height(50).margin(top: 30)
                    .backgroundColor(0xCC333333).fontColor(0xFFFFFF).borderRadius(25)
                    .onClick({ _ => this.getUIContext().getRouter().back() })
            }
        }
    }
}