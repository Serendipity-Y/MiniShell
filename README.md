# MiniShell

MiniShell 是一款面向个人使用的 macOS 原生 SSH / SFTP 客户端。它使用 SwiftUI 构建，提供中文界面、会话管理、嵌入式多标签终端，以及本机与远端双栏文件传输。

> 当前只支持 SSH 和 SFTP；不支持 Telnet、FTP、S3 或其他协议。

## 功能

- 保存 SSH 会话，支持密码和私钥认证；密码仅存放在 macOS 钥匙串。
- 双击会话即可在主窗口右侧打开终端；可同时保留并切换多个会话标签。
- 终端支持中文输入和显示、窗口缩放后的尺寸同步，以及复制会话。
- 使用 SFTP 打开本机 / 远端双栏文件管理器，支持拖拽上传与下载。
- 传输进度集中显示在工具栏的传输提示中。
- 首次连接服务器时显示主机密钥指纹；确认后会校验后续连接，密钥变化将被拒绝。

## 环境要求

- macOS 15 或更高版本
- Xcode 16 或更高版本
- 可用的 SSH 服务器账号

## 本地构建

```bash
git clone <你的仓库地址>
cd MacOS-Xshell
open macSCP.xcodeproj
```

首次打开后等待 Xcode 解析 Swift Package Manager 依赖，然后选择 `macSCP` scheme 运行。

若只需安装本地调试版本，可双击根目录的 [构建并安装.command](构建并安装.command)。它会构建并安装到“应用程序”目录，旧版本会备份在本项目的 `build/local-install/backups` 中。

## 安全说明

- 连接密码不会写入项目文件、日志或用户默认设置，仅使用 macOS Keychain 保存。
- 主机密钥确认属于首次信任（TOFU）机制。首次使用时，请务必通过可信渠道核对指纹。
- 请勿提交 `.env`、私钥、证书、签名材料或任何真实服务器凭据。

漏洞反馈方式见 [SECURITY.md](SECURITY.md)。

## 技术依赖

- [Citadel](https://github.com/Orlandos-nl/Citadel)：SSH 与 SFTP
- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)：终端模拟
- [SwiftNIO SSH](https://github.com/apple/swift-nio-ssh)：SSH 协议实现

## 致谢与许可证

本项目基于 [macSCP](https://github.com/macnev2013/macSCP) 继续开发，保留原项目的许可证文件与既有版权声明。

本仓库当前采用 [CC0 1.0](LICENSE) 许可。CC0 非常宽松，允许他人自由使用、修改和再发布；公开前请确认这符合你的授权意图。
