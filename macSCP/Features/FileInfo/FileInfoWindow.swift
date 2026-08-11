//
//  FileInfoWindow.swift
//  macSCP
//
//  Window wrapper for file info
//

import SwiftUI

struct FileInfoWindow: View {
    let windowId: String
    @State private var viewModel: FileInfoViewModel?
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
                    Text("此窗口的数据已丢失。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("关闭窗口") {
                        dismiss()
                    }
                }
                .padding(32)
            } else if let viewModel = viewModel {
                FileInfoView(viewModel: viewModel)
                    .navigationTitle("信息 - \(viewModel.fileName)")
            } else {
                LoadingView(message: "正在加载…")
                    .task {
                        initializeViewModel()
                    }
            }
        }
        .frame(width: WindowSize.fileInfo.width, height: WindowSize.fileInfo.height)
    }

    @MainActor
    private func initializeViewModel() {
        let windowManager = WindowManager.shared

        guard let data = windowManager.getFileInfoData(for: windowId) else {
            logError("No file info data found for ID: \(windowId)", category: .ui)
            openWindow(id: WindowID.main)
            dismiss()
            return
        }

        viewModel = FileInfoViewModel(
            file: data.file,
            connectionName: data.connectionName
        )
    }
}

// MARK: - Preview
#Preview {
    FileInfoWindow(windowId: "preview")
}
