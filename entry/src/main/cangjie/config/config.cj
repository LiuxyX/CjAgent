// 注意：这里的 package 名字要和你项目里其他文件保持一致
package ohos_app_cangjie_entry.config

// ==========================================
// ⚙️ 全局网络配置文件 (每天只需改这里一次)
// ==========================================

// 1. 填入你电脑今天的局域网 IPv4 地址
public let HOST_IP: String = "10.135.101.132"

// 2. 真实系统地址 (Agent 聊天用，连接 8000 端口)
public let REAL_SERVER_URL: String = "http://${HOST_IP}:8000"

// 3. 模拟测试地址 (大屏看板用，连接 8002 端口)
public let MOCK_SERVER_URL: String = "http://${HOST_IP}:8002"
