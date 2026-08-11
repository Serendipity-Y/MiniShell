//
//  SidebarView.swift
//  macSCP
//
//  Sidebar view for connection folders - Minimal macOS style
//

import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Bindable var viewModel: ConnectionListViewModel
    @State private var folderToRename: Folder?
    @State private var renameText = ""
    @State private var isShowingRenameAlert = false

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $viewModel.selectedConnectionId) {
                Section("会话管理器") {
                    Label("会话管理器", systemImage: "rectangle.3.group")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                }

                Section {
                    Button {
                        viewModel.selectedSidebarItem = .allConnections
                        viewModel.selectedConnectionId = nil
                    } label: {
                        Label {
                            HStack {
                                Text("全部连接")
                                Spacer()
                                Text("\(viewModel.totalConnectionCount)")
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "server.rack")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .dropDestination(for: Connection.self) { connections, _ in
                        for connection in connections {
                            Task { await viewModel.moveConnection(connection, to: nil) }
                        }
                        return true
                    }

                    connectionRows
                } header: {
                    Text(listTitle)
                }

                Section("文件夹") {
                    ForEach(viewModel.folders) { folder in
                        Button {
                            viewModel.selectedSidebarItem = .folder(folder.id)
                            viewModel.selectedConnectionId = nil
                        } label: {
                            FolderRowView(
                                folder: folder,
                                connectionCount: viewModel.connectionCount(for: folder.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .dropDestination(for: Connection.self) { connections, _ in
                            for connection in connections {
                                Task { await viewModel.moveConnection(connection, to: folder) }
                            }
                            return true
                        }
                        .contextMenu {
                            Button {
                                folderToRename = folder
                                renameText = folder.name
                                isShowingRenameAlert = true
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                viewModel.confirmDeleteFolder(folder)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { source, destination in
                        viewModel.reorderFolders(from: source, to: destination)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            connectionInfoPanel
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.isShowingNewConnectionSheet = true
                } label: {
                    Label("新建连接", systemImage: "square.and.pencil")
                }
                .help("新建连接")

                Button {
                    viewModel.isShowingNewFolderSheet = true
                } label: {
                    Label("新建文件夹", systemImage: "folder.badge.plus")
                }
                .help("新建文件夹")
            }
        }
        .alert("重命名文件夹", isPresented: $isShowingRenameAlert) {
            TextField("文件夹名称", text: $renameText)
            Button("重命名") {
                let name = renameText.trimmed
                if !name.isEmpty, let folder = folderToRename {
                    Task { await viewModel.renameFolder(folder, to: name) }
                }
                folderToRename = nil
                renameText = ""
            }
            .keyboardShortcut(.defaultAction)
            Button("取消", role: .cancel) {
                folderToRename = nil
                renameText = ""
            }
        } message: {
            Text("请输入文件夹的新名称。")
        }
    }

    private var listTitle: String {
        switch viewModel.selectedSidebarItem {
        case .allConnections:
            return "全部连接"
        case .folder(let id):
            return viewModel.folders.first { $0.id == id }?.name ?? "文件夹"
        }
    }

    @ViewBuilder
    private var connectionInfoPanel: some View {
        if let connection = viewModel.selectedConnection {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 7) {
                GridRow {
                    Text("名称")
                    Text(connection.name)
                }
                GridRow {
                    Text("主机")
                    Text(connection.host)
                }
                GridRow {
                    Text("端口")
                    Text("\(connection.port)")
                }
                GridRow {
                    Text("协议")
                    Text("SSH")
                }
                GridRow {
                    Text("用户名")
                    Text(connection.username)
                }
            }
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        } else {
            Text("选择会话后显示连接信息")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .center)
        }
    }

    @ViewBuilder
    private var connectionRows: some View {
        switch viewModel.state {
        case .idle, .loading:
            HStack {
                ProgressView()
                Text("正在加载连接…")
                    .foregroundStyle(.secondary)
            }
        case .success:
            if viewModel.filteredConnections.isEmpty {
                Text(viewModel.searchText.isEmpty ? "暂无连接" : "没有匹配的连接")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.filteredConnections) { connection in
                    ConnectionRowView(connection: connection)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            viewModel.requestTerminal(for: connection)
                        }
                        .draggable(connection)
                        .contextMenu {
                            connectionContextMenu(for: connection)
                        }
                        .tag(connection.id)
                }
            }
        case .error(let error):
            Text(error.localizedDescription)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private func connectionContextMenu(for connection: Connection) -> some View {
        Button {
            viewModel.connectToServer(connection)
        } label: {
            Label("打开文件传输", systemImage: "folder")
        }

        Button {
            viewModel.requestTerminal(for: connection)
        } label: {
            Label("打开终端", systemImage: "terminal")
        }

        Divider()

        Button {
            viewModel.editConnection(connection)
        } label: {
            Label("编辑", systemImage: "pencil")
        }

        Button {
            Task { await viewModel.duplicateConnection(connection) }
        } label: {
            Label("复制", systemImage: "plus.square.on.square")
        }

        Divider()

        Button(role: .destructive) {
            Task { await viewModel.deleteConnection(connection) }
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
}

// MARK: - Folder Row
struct FolderRowView: View {
    let folder: Folder
    let connectionCount: Int

    var body: some View {
        Label {
            Text(folder.name)
        } icon: {
            Image(nsImage: NSWorkspace.shared.icon(for: .folder))
                .resizable()
                .frame(width: 20, height: 20)
        }
        .badge("\(connectionCount)")
    }
}

// MARK: - Preview
#Preview {
    SidebarView(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
        .frame(width: 250)
}
