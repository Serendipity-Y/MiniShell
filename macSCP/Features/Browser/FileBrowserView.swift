//
//  FileBrowserView.swift
//  macSCP
//
//  Main file browser view
//

import SwiftUI

struct FileBrowserView: View {
    @Bindable var viewModel: FileBrowserViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var localViewModel = LocalFileBrowserViewModel()

    init(viewModel: FileBrowserViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            connectionBar

            HSplitView {
                localPane
                    .frame(minWidth: 360, maxWidth: .infinity)

                remotePane
                    .frame(minWidth: 360, maxWidth: .infinity)
            }

            Divider()

            statusBar
        }
        .frame(minWidth: WindowSize.minFileBrowser.width, minHeight: WindowSize.minFileBrowser.height)
        .navigationTitle(viewModel.currentPath == "/" ? viewModel.connection.name : (viewModel.currentPath as NSString).lastPathComponent)
        .navigationSubtitle(viewModel.isConnected ? viewModel.connection.connectionString : "Disconnected")
        .toolbar(id: "browserToolbar") {
            // Navigation group
            ToolbarItem(id: "back", placement: .navigation) {
                Button {
                    Task { await viewModel.goBack() }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!viewModel.canGoBack)
                .help("返回")
            }

            ToolbarItem(id: "forward", placement: .navigation) {
                Button {
                    Task { await viewModel.goForward() }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.canGoForward)
                .help("前进")
            }

            // Primary actions
            ToolbarItem(id: "newItem", placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.isShowingNewFolderSheet = true
                    } label: {
                        Label("新建文件夹", systemImage: "folder.badge.plus")
                    }

                    Button {
                        viewModel.isShowingNewFileSheet = true
                    } label: {
                        Label("新建文件", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Label("新建", systemImage: "plus")
                }
                .help("新建文件或文件夹")
            }

            ToolbarItem(id: "upload", placement: .primaryAction) {
                Button {
                    Task { await viewModel.uploadFiles() }
                } label: {
                    Label("上传", systemImage: "square.and.arrow.up")
                }
                .help("上传文件")
            }

            ToolbarItem(id: "delete", placement: .primaryAction) {
                Button {
                    viewModel.confirmDeleteSelected()
                } label: {
                    Label("删除", systemImage: "trash")
                }
                .disabled(viewModel.selectedFiles.isEmpty)
                .help("删除所选项目")
            }

            ToolbarItem(id: "spacer1", placement: .primaryAction) {
                Spacer()
            }

            ToolbarItem(id: "terminal", placement: .primaryAction) {
                Button {
                    viewModel.openTerminal()
                } label: {
                    Label("终端", systemImage: "terminal")
                }
                .disabled(!viewModel.isConnected)
                .help("打开终端")
            }

            // Transfers
            ToolbarItem(id: "transfers", placement: .primaryAction) {
                TransfersToolbarButton(viewModel: viewModel)
            }

            // View options
            ToolbarItem(id: "hiddenFiles", placement: .primaryAction) {
                Toggle(isOn: $viewModel.showHiddenFiles) {
                    Label(
                        viewModel.showHiddenFiles ? "隐藏隐藏文件" : "显示隐藏文件",
                        systemImage: viewModel.showHiddenFiles ? "eye.fill" : "eye.slash"
                    )
                }
                .help("显示或隐藏隐藏文件")
            }

            ToolbarItem(id: "sort", placement: .primaryAction) {
                Menu {
                    ForEach(RemoteFile.SortCriteria.allCases, id: \.self) { criteria in
                        Button {
                            if viewModel.sortCriteria == criteria {
                                viewModel.sortAscending.toggle()
                            } else {
                                viewModel.sortCriteria = criteria
                                viewModel.sortAscending = true
                            }
                        } label: {
                            HStack {
                                Text(criteria.rawValue)
                                if viewModel.sortCriteria == criteria {
                                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                }
                            }
                        }
                    }
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down")
                }
                .help("排序选项")
            }
        }
        .task {
            await viewModel.connect()
        }
        .sheet(isPresented: $viewModel.isShowingNewFolderSheet) {
            NameInputSheet.newFolder(
                onConfirm: { name in
                    Task {
                        await viewModel.createFolder(name: name)
                    }
                },
                onCancel: {
                    viewModel.isShowingNewFolderSheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.isShowingNewFileSheet) {
            NameInputSheet.newFile(
                onConfirm: { name in
                    Task {
                        await viewModel.createFile(name: name)
                    }
                },
                onCancel: {
                    viewModel.isShowingNewFileSheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.isShowingRenameSheet) {
            if let file = viewModel.fileToRename {
                NameInputSheet.rename(
                    currentName: file.name,
                    onConfirm: { newName in
                        Task {
                            await viewModel.renameFile(file, to: newName)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingRenameSheet = false
                        viewModel.fileToRename = nil
                    }
                )
            }
        }
        .alert("删除文件", isPresented: $viewModel.isShowingDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                Task {
                    await viewModel.deleteFiles(viewModel.filesToDelete)
                }
            }
        } message: {
            let count = viewModel.filesToDelete.count
            Text("确定要删除 \(count) 个项目吗？此操作无法撤销。")
        }
        .errorAlert($viewModel.error)
        .onDisappear {
            Task {
                await viewModel.disconnect()
            }
        }
        .onChange(of: viewModel.pendingFileInfoWindowId) { _, windowId in
            if let windowId = windowId {
                openWindow(id: WindowID.fileInfo, value: windowId)
                viewModel.clearPendingFileInfoWindow()
            }
        }
        .onChange(of: viewModel.pendingEditorWindowId) { _, windowId in
            if let windowId = windowId {
                openWindow(id: WindowID.fileEditor, value: windowId)
                viewModel.clearPendingEditorWindow()
            }
        }
        .onChange(of: viewModel.pendingTerminalWindowId) { _, windowId in
            if let windowId = windowId {
                openWindow(id: WindowID.terminal, value: windowId)
                viewModel.clearPendingTerminalWindow()
            }
        }
    }

    private var connectionBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(viewModel.isConnected ? .green : .secondary)
            Text("SFTP")
                .font(.system(size: 12, weight: .semibold))
            Text(viewModel.connection.connectionString)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text(viewModel.isConnected ? "已连接" : "正在连接")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(.bar)
    }

    private var localPane: some View {
        VStack(spacing: 0) {
            FilePaneToolbar(
                title: "本机",
                path: localViewModel.pathDisplayName,
                canGoBack: localViewModel.canGoBack,
                canGoForward: localViewModel.canGoForward,
                canGoUp: localViewModel.canGoUp,
                onBack: { localViewModel.goBack() },
                onForward: { localViewModel.goForward() },
                onUp: { localViewModel.goUp() },
                onRefresh: { localViewModel.loadFiles() }
            )
            NativeLocalFileTableView(viewModel: localViewModel)
        }
        .errorAlert($localViewModel.error)
    }

    private var remotePane: some View {
        VStack(spacing: 0) {
            FilePaneToolbar(
                title: "远端",
                path: viewModel.currentPath,
                canGoBack: viewModel.canGoBack,
                canGoForward: viewModel.canGoForward,
                canGoUp: viewModel.canGoUp,
                onBack: { Task { await viewModel.goBack() } },
                onForward: { Task { await viewModel.goForward() } },
                onUp: { Task { await viewModel.goUp() } },
                onRefresh: { Task { await viewModel.refresh() } }
            )

            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: viewModel.isConnected ? "正在读取远端目录…" : "正在连接 SFTP…")
            case .success:
                NativeFileTableView(
                    viewModel: viewModel,
                    onDoubleClick: { file in
                        guard file.isDirectory else { return }
                        Task { await viewModel.navigateTo(file.path) }
                    },
                    onGetInfo: showFileInfo,
                    onOpenEditor: nil
                )
            case .error(let error):
                ErrorView(error: error) {
                    Task {
                        if viewModel.isConnected {
                            await viewModel.refresh()
                        } else {
                            await viewModel.connect()
                        }
                    }
                }
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            // Connection status
            HStack(spacing: 5) {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 7, height: 7)

                Text(viewModel.isConnected ? "Connected" : "Disconnected")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Active transfers indicator (clicking opens the popover)
            if viewModel.hasActiveTransfers {
                ActiveTransfersIndicator(viewModel: viewModel)
            }

            // Clipboard status
            if viewModel.hasClipboardItems && !viewModel.hasActiveTransfers {
                ClipboardStatusView(displayText: viewModel.clipboardDisplayText)
            }

            Spacer()

            // File count
            HStack(spacing: 6) {
                Text("\(viewModel.sortedFiles.count) 个项目")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if !viewModel.selectedFiles.isEmpty {
                    Text("已选择 \(viewModel.selectedFiles.count) 个")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func showFileInfo(_ file: RemoteFile) {
        viewModel.showFileInfo(file)
    }
}

private struct FilePaneToolbar: View {
    let title: String
    let path: String
    let canGoBack: Bool
    let canGoForward: Bool
    let canGoUp: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onUp: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button(action: onBack) { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain)
                    .disabled(!canGoBack)
                    .help("返回")
                Button(action: onForward) { Image(systemName: "chevron.right") }
                    .buttonStyle(.plain)
                    .disabled(!canGoForward)
                    .help("前进")
                Button(action: onUp) { Image(systemName: "arrow.up") }
                    .buttonStyle(.plain)
                    .disabled(!canGoUp)
                    .help("上级目录")
                Button(action: onRefresh) { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.plain)
                    .help("刷新")
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(.bar)

            HStack(spacing: 7) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(path)
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color(nsColor: .controlBackgroundColor))
            Divider()
        }
    }
}

// MARK: - Clipboard Status View
struct ClipboardStatusView: View {
    let displayText: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Text(displayText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Active Transfers Indicator
struct ActiveTransfersIndicator: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        Button {
            viewModel.isShowingTransfersPopover = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)

                ProgressView(value: viewModel.overallProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 50)

                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    FileBrowserView(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        )
    )
}
