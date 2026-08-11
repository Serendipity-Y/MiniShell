# Xshell-Style SFTP Workspace Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不增加协议或复制第三方品牌资产的前提下，将 MiniShell 的 SSH/SFTP 工作布局调整为高密度桌面文件传输体验：SFTP 左本机、右远端、可直接拖拽传输，并提供会话侧栏显隐与终端内 SFTP 快捷入口。

**Architecture:** 保留现有 SSH、SFTP、SwiftTerm 与 Citadel/NIOSSH 基础设施。SFTP 窗口改造成独立本机/远端双栏：本机栏使用本地目录视图模型和原生 `NSTableView`，远端栏复用现有 `NativeFileTableView` 的文件承诺下载能力；底部直接复用既有传输状态。终端快捷入口只复用当前连接参数打开现有 SFTP 窗口，不宣称或重构为同一 SSH 通道。

**Tech Stack:** Swift 6、SwiftUI、AppKit、SwiftTerm、Citadel/NIOSSH。

---

## 范围与边界

- 仅支持 SSH 与 SFTP；不实现 FTP、Telnet 或其他协议。
- 参考截图的空间布局、信息层级和操作路径；不使用 Xshell/Xftp 名称、Logo、图标或其他专有资源。
- 不修改密码保存方式；连接凭据继续只在内存/Keychain 流程中使用。
- 不做 SSH 到 SFTP 的底层会话复用重构；快捷按钮打开现有 SFTP 连接流程。

## 阶段 1：双栏 SFTP 文件工作区

**Files:**
- Create: `macSCP/Features/Browser/LocalFileBrowserViewModel.swift`
- Create: `macSCP/Features/Browser/Components/NativeLocalFileTableView.swift`
- Create: `macSCP/Features/Browser/Components/TransferQueueView.swift`
- Modify: `macSCP/Features/Browser/FileBrowserView.swift`
- Modify: `macSCP/Features/Browser/Components/NativeFileTableView.swift`
- Modify: `macSCP/Domain/Models/RemoteFile.swift`

1. 创建本地目录浏览视图模型：读取当前目录、前进/后退/上级、双击目录进入、刷新、选择状态；默认起点为桌面。
2. 使用原生 `NSTableView` 展示本地文件，提供与远端一致的中文列表列、外部文件 URL 拖出能力。
3. 本地栏接受远端 `NSFilePromiseProvider`，下载完成后刷新目录；远端栏继续接受本地文件 URL，从而实现双向直接拖拽。
4. 用 `HSplitView` 建立左本机、右远端的等宽可调工作区，并用独立路径栏和导航按钮保持两端目录独立。
5. 在底部加入常驻传输队列，展示传输名称、状态、进度、大小、本机路径与远端路径；保留取消和清理已完成记录的操作。
6. 把全部新增用户可见文字改为中文，并修正已有远端列表英文列标题/排序文字。

**Acceptance:** 构建成功；本机和远端同时显示；从本机拖至远端触发上传；从远端拖至本机触发下载；传输队列实时显示状态。

## 阶段 2：主界面会话布局与终端快捷入口

**Files:**
- Modify: `macSCP/Features/Connections/ConnectionListView.swift`
- Modify: `macSCP/Features/Connections/Components/SidebarView.swift`
- Modify: `macSCP/Features/Terminal/TerminalWindow.swift`
- Modify: `macSCP/Features/Terminal/TerminalView.swift`

1. 将已有会话侧栏整理为紧凑会话管理区，保留搜索、会话树和当前连接信息。
2. 增加明确的中文“显示/隐藏会话栏”按钮，并确保隐藏后主工作区可用宽度增加。
3. 在终端工具栏增加“SFTP 文件传输”快捷按钮，使用当前终端连接参数打开 SFTP 文件工作区。
4. 保持终端会话、窗口缩放和断开重连行为不变。

**Acceptance:** 会话栏可显隐；终端可一键打开对应 SFTP 工作区；不新增连接协议。

## 阶段 3：真实环境回归

**Files:** 仅修复回归中确认的最小问题。

1. 使用已提供的真实 SSH 主机验证密码登录、终端交互、中文显示、窗口缩放和重连。
2. 使用双栏 SFTP 验证远端读取、本地拖拽上传、远端拖拽下载，以及文件内容一致性。
3. 对远端测试文件的永久删除，在实际执行前请求即时确认。
4. 以隔离构建目录执行构建；记录真实覆盖范围与未覆盖限制。

**Acceptance:** SSH/SFTP 核心路径完成真实验证；只有确认的问题被修复；不产生明文凭据或测试残留。

## 验证命令

```bash
xcodebuild build -project macSCP.xcodeproj -scheme macSCP \
  -derivedDataPath /tmp/minishell-xshell-layout-build \
  CODE_SIGNING_ALLOWED=NO
git diff --check
```
