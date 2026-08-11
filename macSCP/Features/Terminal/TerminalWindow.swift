//
//  TerminalWindow.swift
//  macSCP
//
//  Window wrapper for the terminal
//

import SwiftUI

struct TerminalWindow: View {
    let windowId: String
    @State private var viewModel: TerminalViewModel?
    @State private var terminalData: TerminalWindowData?
    @State private var showMissingDataError = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if showMissingDataError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("会话已失效")
                        .font(.headline)
                    Text("此窗口的会话数据已丢失，请从主窗口重新连接。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("关闭窗口") {
                        dismiss()
                    }
                }
                .padding(32)
            } else if let viewModel = viewModel {
                TerminalContentView(viewModel: viewModel, onOpenSFTP: openSFTPWorkspace)
            } else {
                LoadingView(message: "正在初始化…")
                    .task {
                        initializeViewModel()
                    }
            }
        }
        .frame(minWidth: WindowSize.minTerminal.width, minHeight: WindowSize.minTerminal.height)
    }

    @MainActor
    private func initializeViewModel() {
        let windowManager = WindowManager.shared

        guard let data = windowManager.getTerminalData(for: windowId) else {
            logError("No terminal window data found for ID: \(windowId)", category: .ui)
            showMissingDataError = true
            return
        }

        let container = DependencyContainer.shared
        let session = container.makeTerminalSession()

        viewModel = container.makeTerminalViewModel(
            connectionName: data.connectionName,
            session: session,
            connectionData: data
        )
        terminalData = data
    }

    @MainActor
    private func openSFTPWorkspace() {
        guard let data = terminalData else { return }
        let browserData = FileBrowserWindowData(
            connectionId: data.connectionId,
            connectionName: data.connectionName,
            host: data.host,
            port: data.port,
            username: data.username,
            password: data.password,
            authMethod: data.authMethod,
            privateKeyPath: data.privateKeyPath
        )
        let browserWindowId = WindowManager.shared.storeFileBrowserData(browserData)
        openWindow(id: WindowID.fileBrowser, value: browserWindowId)
    }
}

// MARK: - Preview

#Preview {
    TerminalWindow(windowId: "preview")
}
