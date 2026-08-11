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
        List(selection: $viewModel.selectedSidebarItem) {
            Section {
                Label("会话管理器", systemImage: "rectangle.3.group")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // All Connections
            NavigationLink(value: SidebarSelection.allConnections) {
                Label {
                    Text("全部连接")
                } icon: {
                    Image(systemName: "server.rack")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .dropDestination(for: Connection.self) { connections, _ in
                for connection in connections {
                    Task { await viewModel.moveConnection(connection, to: nil) }
                }
                return true
            }

            // Folders Section
            Section("文件夹") {
                ForEach(viewModel.folders) { folder in
                    NavigationLink(value: SidebarSelection.folder(folder.id)) {
                        FolderRowView(
                            folder: folder,
                            connectionCount: viewModel.connectionCount(for: folder.id)
                        )
                    }
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
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
