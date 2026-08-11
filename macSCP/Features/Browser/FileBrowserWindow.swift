//
//  FileBrowserWindow.swift
//  macSCP
//
//  Window wrapper for the file browser
//

import SwiftUI

struct FileBrowserWindow: View {
    let windowId: String
    @State private var viewModel: FileBrowserViewModel?
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
                FileBrowserView(viewModel: viewModel)
                    .navigationTitle(viewModel.connection.name)
            } else {
                LoadingView(message: "正在初始化…")
                    .task {
                        initializeViewModel()
                    }
            }
        }
        .frame(minWidth: WindowSize.minFileBrowser.width, minHeight: WindowSize.minFileBrowser.height)
    }

    @MainActor
    private func initializeViewModel() {
        let windowManager = WindowManager.shared

        guard let data = windowManager.getFileBrowserData(for: windowId) else {
            logError("No window data found for ID: \(windowId)", category: .ui)
            openWindow(id: WindowID.main)
            dismiss()
            return
        }

        let container = DependencyContainer.shared

        let connection = Connection(
            id: data.connectionId,
            name: data.connectionName,
            host: data.host,
            port: data.port,
            username: data.username,
            authMethod: data.authMethod,
            privateKeyPath: data.privateKeyPath
        )

        let sftpSession = container.makeSFTPSession()
        viewModel = container.makeFileBrowserViewModel(
            connection: connection,
            sftpSession: sftpSession,
            password: data.password
        )
    }
}

// MARK: - Preview
#Preview {
    FileBrowserWindow(windowId: "preview")
}
