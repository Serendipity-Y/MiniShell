//
//  ConnectionListView.swift
//  macSCP
//
//  Main view for managing SSH connections
//

import SwiftUI

struct ConnectionListView: View {
    /// The main window can be recomputed when its appearance preferences change.
    /// Keep one list model for the lifetime of that window so its load task is
    /// not cancelled and replaced while it is fetching saved connections.
    @State private var viewModel: ConnectionListViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var newFolderName = ""
    @State private var terminalWorkspace = TerminalWorkspaceViewModel()

    init(viewModel: ConnectionListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @ViewBuilder
    private var detailColumn: some View {
        if terminalWorkspace.hasTabs {
            TerminalWorkspaceView(
                workspace: terminalWorkspace,
                onOpenSFTP: openSFTPWorkspace
            )
        } else if let connection = viewModel.selectedConnection {
            ConnectionDetailView(
                connection: connection,
                onConnect: {
                    viewModel.connectToServer(connection)
                },
                onOpenTerminal: {
                    viewModel.requestTerminal(for: connection)
                },
                onEdit: {
                    viewModel.editConnection(connection)
                },
                onDuplicate: {
                    Task {
                        await viewModel.duplicateConnection(connection)
                    }
                },
                onDelete: {
                    Task {
                        await viewModel.deleteConnection(connection)
                    }
                }
            )
        } else {
            ContentUnavailableView(
                "未选择连接",
                systemImage: "server.rack",
                description: Text("选择一个连接以查看详情。")
            )
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Color.clear.frame(width: 0, height: 0)
                }
            }
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300, max: 380)
        } detail: {
            detailColumn
        }
        .navigationTitle("")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .searchable(text: $viewModel.searchText, prompt: "搜索连接")
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.isShowingNewConnectionSheet) {
            ConnectionFormSheet(
                mode: .create,
                folders: viewModel.folders,
                onSave: { connection, password in
                    Task {
                        await viewModel.saveConnection(connection, password: password)
                    }
                },
                onCancel: {
                    viewModel.isShowingNewConnectionSheet = false
                }
            )
        }
        .sheet(isPresented: $viewModel.isShowingEditConnectionSheet) {
            if let connection = viewModel.connectionToEdit {
                ConnectionFormSheet(
                    mode: .edit(connection),
                    savedPassword: viewModel.getSavedPassword(for: connection),
                    folders: viewModel.folders,
                    onSave: { updatedConnection, password in
                        Task {
                            await viewModel.updateConnection(updatedConnection, password: password)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingEditConnectionSheet = false
                        viewModel.connectionToEdit = nil
                    }
                )
            }
        }
        .alert("新建文件夹", isPresented: $viewModel.isShowingNewFolderSheet) {
            TextField("文件夹名称", text: $newFolderName)
            Button("创建") {
                let name = newFolderName.trimmed
                if !name.isEmpty {
                    Task { await viewModel.createFolder(name: name) }
                }
                newFolderName = ""
            }
            .keyboardShortcut(.defaultAction)
            Button("取消", role: .cancel) {
                newFolderName = ""
            }
        } message: {
            Text("请输入新文件夹名称。")
        }
        .sheet(isPresented: $viewModel.isShowingPasswordPrompt) {
            if let connection = viewModel.connectionToConnect {
                PasswordPromptSheet(
                    connectionName: connection.name,
                    onConnect: { password in
                        viewModel.connectWithPassword(password)
                    },
                    onCancel: {
                        viewModel.cancelConnect()
                    }
                )
            }
        }
        .alert("删除文件夹", isPresented: $viewModel.isShowingDeleteFolderAlert) {
            Button("取消", role: .cancel) {
                viewModel.cancelDeleteFolder()
            }
            Button("删除", role: .destructive) {
                if let folder = viewModel.folderToDelete {
                    Task {
                        await viewModel.deleteFolder(folder)
                    }
                }
            }
        } message: {
            if let folder = viewModel.folderToDelete {
                let count = viewModel.connectionCount(for: folder.id)
                Text("确定要删除“\(folder.name)”吗？\(count > 0 ? "其中的 \(count) 个连接将移至全部连接。" : "")")
            }
        }
        .errorAlert($viewModel.error)
        .onChange(of: viewModel.pendingWindowId) { _, windowId in
            if let windowId = windowId {
                logInfo("Opening file browser window with ID: \(windowId)", category: .ui)
                openWindow(id: WindowID.fileBrowser, value: windowId)
                viewModel.clearPendingWindow()
            }
        }
        .onChange(of: viewModel.terminalRequestID) { _, _ in
            if let data = viewModel.pendingTerminalData {
                terminalWorkspace.openTerminal(with: data)
                viewModel.clearPendingTerminalRequest()
            }
        }
    }

    private func openSFTPWorkspace(_ data: TerminalWindowData) {
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
    ConnectionListView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
}
