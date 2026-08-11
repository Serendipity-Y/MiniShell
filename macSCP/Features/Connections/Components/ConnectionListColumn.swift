//
//  ConnectionListColumn.swift
//  macSCP
//
//  List view displaying connections for the middle column (Apple Notes style)
//

import SwiftUI

struct ConnectionListColumn: View {
    @Bindable var viewModel: ConnectionListViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: "正在加载连接…")

            case .success:
                if viewModel.filteredConnections.isEmpty {
                    emptyStateView
                } else {
                    connectionList
                }

            case .error(let error):
                ErrorView(error: error) {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(listTitle)
        .navigationSubtitle("\(viewModel.filteredConnections.count) 个连接")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.isShowingNewConnectionSheet = true
                } label: {
                    Label("新建连接", systemImage: "square.and.pencil")
                }
                .help("新建连接")
            }
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
    private var emptyStateView: some View {
        if viewModel.searchText.isEmpty {
            switch viewModel.selectedSidebarItem {
            case .allConnections:
                EmptyStateView(
                    icon: "server.rack",
                    title: "暂无连接",
                    message: "新建 SSH 连接后，即可管理远程文件。",
                    actionTitle: "新建连接"
                ) {
                    viewModel.isShowingNewConnectionSheet = true
                }
            case .folder:
                EmptyStateView(
                    icon: "folder",
                    title: "文件夹为空",
                    message: "此文件夹中没有连接。可将连接拖到这里或新建连接。",
                    actionTitle: "新建连接"
                ) {
                    viewModel.isShowingNewConnectionSheet = true
                }
            }
        } else {
            EmptyStateView.noSearchResults
        }
    }

    private var connectionList: some View {
        List(viewModel.filteredConnections, selection: $viewModel.selectedConnectionId) { connection in
            ConnectionRowView(connection: connection)
                .draggable(connection)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteConnection(connection) }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .contextMenu {
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
                        Task {
                            await viewModel.duplicateConnection(connection)
                        }
                    } label: {
                        Label("复制", systemImage: "plus.square.on.square")
                    }

                    Divider()

                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteConnection(connection)
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .tag(connection.id)
        }
        .listStyle(.inset)
        .onKeyPress(.return) {
            if let connection = viewModel.selectedConnection {
                viewModel.connectToServer(connection)
                return .handled
            }
            return .ignored
        }
        .onDeleteCommand {
            if let connection = viewModel.selectedConnection {
                Task { await viewModel.deleteConnection(connection) }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ConnectionListColumn(viewModel: DependencyContainer.shared.makeConnectionListViewModel())
}
