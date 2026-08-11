//
//  TerminalWorkspaceView.swift
//  macSCP
//
//  In-window terminal tabs for the main session workspace
//

import SwiftUI

struct TerminalTab: Identifiable {
    let id = UUID()
    let data: TerminalWindowData
    let viewModel: TerminalViewModel

    var title: String {
        data.connectionName
    }
}

@MainActor
@Observable
final class TerminalWorkspaceViewModel {
    private(set) var tabs: [TerminalTab] = []
    var selectedTabID: UUID?

    var hasTabs: Bool {
        !tabs.isEmpty
    }

    func openTerminal(with data: TerminalWindowData) {
        let container = DependencyContainer.shared
        let viewModel = container.makeTerminalViewModel(
            connectionName: data.connectionName,
            session: container.makeTerminalSession(),
            connectionData: data
        )
        let tab = TerminalTab(data: data, viewModel: viewModel)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func closeTerminal(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = tabs.remove(at: index)

        if selectedTabID == id {
            selectedTabID = tabs.indices.contains(index) ? tabs[index].id : tabs.last?.id
        }

        Task {
            await tab.viewModel.cleanup()
        }
    }

    func duplicateTerminal(id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        openTerminal(with: tab.data)
    }
}

struct TerminalWorkspaceView: View {
    @Bindable var workspace: TerminalWorkspaceViewModel
    let onOpenSFTP: (TerminalWindowData) -> Void

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            Divider()

            ZStack {
                ForEach(workspace.tabs) { tab in
                    TerminalContentView(
                        viewModel: tab.viewModel,
                        onOpenSFTP: { onOpenSFTP(tab.data) },
                        disconnectOnDisappear: false,
                        showsToolbar: false
                    )
                    .opacity(tab.id == workspace.selectedTabID ? 1 : 0)
                    .allowsHitTesting(tab.id == workspace.selectedTabID)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(id: "terminalWorkspaceToolbar") {
            if let selectedTab {
                ToolbarItem(id: "sftp", placement: .primaryAction) {
                    Button {
                        onOpenSFTP(selectedTab.data)
                    } label: {
                        Label("SFTP 文件传输", systemImage: "folder.badge.gearshape")
                    }
                    .help("打开本机与远端双栏文件传输")
                }

                ToolbarItem(id: "reconnect", placement: .primaryAction) {
                    Button {
                        Task {
                            await selectedTab.viewModel.reconnect()
                        }
                    } label: {
                        Label("重新连接", systemImage: "arrow.clockwise")
                    }
                    .disabled(selectedTab.viewModel.state == .connecting)
                    .help("重新连接")
                }
            }
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(workspace.tabs) { tab in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor(for: tab.viewModel))
                            .frame(width: 7, height: 7)

                        Text(tab.title)
                            .lineLimit(1)

                        Button {
                            workspace.closeTerminal(id: tab.id)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .help("关闭终端")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(tab.id == workspace.selectedTabID ? Color.accentColor.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        workspace.selectedTabID = tab.id
                    }
                    .contextMenu {
                        Button {
                            workspace.duplicateTerminal(id: tab.id)
                        } label: {
                            Label("复制会话", systemImage: "plus.square.on.square")
                        }

                        Divider()

                        Button(role: .destructive) {
                            workspace.closeTerminal(id: tab.id)
                        } label: {
                            Label("关闭终端", systemImage: "xmark")
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .scrollIndicators(.hidden)
        .background(.bar)
    }

    private func statusColor(for viewModel: TerminalViewModel) -> Color {
        switch viewModel.state {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected, .error:
            return .secondary
        }
    }

    private var selectedTab: TerminalTab? {
        workspace.tabs.first { $0.id == workspace.selectedTabID }
    }

}
