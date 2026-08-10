//
//  FileListView.swift
//  macSCP
//
//  List view for displaying files in the browser - Finder style with native drag and drop
//

import SwiftUI

struct FileListView: View {
    @Bindable var viewModel: FileBrowserViewModel
    let onGetInfo: (RemoteFile) -> Void

    var body: some View {
        NativeFileTableView(
            viewModel: viewModel,
            onDoubleClick: handleDoubleClick,
            onGetInfo: onGetInfo,
            onOpenEditor: nil
        )
    }

    private func handleDoubleClick(_ file: RemoteFile) {
        Task {
            if file.isDirectory {
                await viewModel.navigateTo(file.path)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    FileListView(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        ),
        onGetInfo: { _ in }
    )
}
