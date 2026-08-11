//
//  ConnectionListView.swift
//  macSCP
//
//  Main view for managing SSH connections
//

import SwiftUI

struct ConnectionListView: View {
    @Bindable var viewModel: ConnectionListViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var newFolderName = ""
    @State private var isSessionSidebarVisible = true

    init(viewModel: ConnectionListViewModel) {
        self.viewModel = viewModel
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let connection = viewModel.selectedConnection {
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
        Group {
            if isSessionSidebarVisible {
                NavigationSplitView {
                    SidebarView(viewModel: viewModel)
                        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
                } content: {
                    ConnectionListColumn(viewModel: viewModel)
                        .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 400)
                } detail: {
                    detailColumn
                }
            } else {
                NavigationSplitView {
                    ConnectionListColumn(viewModel: viewModel)
                        .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 400)
                } detail: {
                    detailColumn
                }
            }
        }
        .navigationTitle("")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    isSessionSidebarVisible.toggle()
                } label: {
                    Label(
                        isSessionSidebarVisible ? "隐藏会话栏" : "显示会话栏",
                        systemImage: "sidebar.leading"
                    )
                }
                .help(isSessionSidebarVisible ? "隐藏会话栏" : "显示会话栏")
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索连接")
        .onChange(of: viewModel.selectedSidebarItem) {
            viewModel.selectedConnectionId = nil
        }
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
        .onChange(of: viewModel.pendingTerminalWindowId) { _, windowId in
            if let windowId = windowId {
                logInfo("Opening terminal window with ID: \(windowId)", category: .ui)
                openWindow(id: WindowID.terminal, value: windowId)
                viewModel.clearPendingTerminalWindow()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ConnectionListView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
}
