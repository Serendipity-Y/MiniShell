//
//  FileEditorWindow.swift
//  macSCP
//
//  Window wrapper for the file editor
//

import SwiftUI

struct FileEditorWindow: View {
    let windowId: String
    @State private var viewModel: FileEditorViewModel?
    @State private var isConnecting = true
    @State private var connectionError: AppError?
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
                    Text("编辑器会话数据已丢失，请从文件传输窗口重新打开该文件。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("关闭窗口") {
                        dismiss()
                    }
                }
                .padding(32)
            } else if let viewModel = viewModel {
                FileEditorView(viewModel: viewModel)
                    .navigationTitle(viewModel.fileName)
            } else if let error = connectionError {
                ErrorView(error: error) {
                    Task {
                        await initializeViewModel()
                    }
                }
            } else {
                LoadingView(message: "正在连接…")
                    .task {
                        await initializeViewModel()
                    }
            }
        }
        .frame(minWidth: WindowSize.fileEditor.width, minHeight: WindowSize.fileEditor.height)
        .onDisappear {
            Task {
                await viewModel?.cleanup()
            }
        }
    }

    @MainActor
    private func initializeViewModel() async {
        let windowManager = WindowManager.shared

        guard let data = windowManager.getFileEditorData(for: windowId) else {
            logError("No editor data found for ID: \(windowId)", category: .ui)
            openWindow(id: WindowID.main)
            dismiss()
            return
        }

        let container = DependencyContainer.shared

        do {
            let session = container.makeSFTPSession()
            switch data.authMethod {
            case .password:
                try await session.connect(
                    host: data.host,
                    port: data.port,
                    username: data.username,
                    password: data.password
                )
            case .privateKey:
                try await session.connect(
                    host: data.host,
                    port: data.port,
                    username: data.username,
                    privateKeyPath: data.privateKeyPath ?? "",
                    passphrase: data.password.isEmpty ? nil : data.password
                )
            }
            let fileRepository = container.makeFileRepository(session: session)

            viewModel = FileEditorViewModel(
                filePath: data.filePath,
                fileName: data.fileName,
                initialContent: data.content,
                fileRepository: fileRepository,
                sftpSession: session
            )
        } catch {
            logError("Failed to connect for editor: \(error)", category: .sftp)
            connectionError = AppError.from(error)
        }
    }
}

// MARK: - Preview
#Preview {
    FileEditorWindow(windowId: "preview")
}
