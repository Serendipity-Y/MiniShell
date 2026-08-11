//
//  MacSCPApp.swift
//  macSCP
//
//  Main application entry point
//

import SwiftUI
import SwiftData

@main
struct MacSCPApp: App {
    @StateObject private var container = DependencyContainer.shared

    init() {
        AppLockManager.shared.lockIfNeeded()
    }

    var body: some Scene {
        // Main Window - Connection List
        WindowGroup {
            ConnectionListView(viewModel: container.makeConnectionListViewModel())
                .appLockOverlay()
                .onAppear {
                    Self.localizeSystemMenuTitles()
                }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.main)
        .commands {
            appCommands
        }

        // File Browser Window
        WindowGroup(id: WindowID.fileBrowser, for: String.self) { $windowId in
            if let windowId = windowId {
                FileBrowserWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileBrowser)

        // File Editor Window
        WindowGroup(id: WindowID.fileEditor, for: String.self) { $windowId in
            if let windowId = windowId {
                FileEditorWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileEditor)

        // File Info Window
        WindowGroup(id: WindowID.fileInfo, for: String.self) { $windowId in
            if let windowId = windowId {
                FileInfoWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.fileInfo)
        .windowResizability(.contentSize)

        // Terminal Window
        WindowGroup(id: WindowID.terminal, for: String.self) { $windowId in
            if let windowId = windowId {
                TerminalWindow(windowId: windowId)
                    .appLockOverlay()
            }
        }
        .modelContainer(container.modelContainer)
        .defaultSize(WindowSize.terminal)

        // Settings Window (Cmd+,)
        Settings {
            SettingsView()
                .appLockOverlay()
        }
    }

    @MainActor
    private static func localizeSystemMenuTitles() {
        let translations = [
            "File": "文件",
            "Edit": "编辑",
            "View": "视图",
            "Window": "窗口",
            "Help": "帮助"
        ]
        for item in NSApp.mainMenu?.items ?? [] {
            if let title = translations[item.title] {
                item.title = title
            }
        }
    }

    // MARK: - Commands
    @CommandsBuilder
    private var appCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("新建连接") {
                // Handled by main window
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("新建文件夹") {
                // Handled by main window
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("刷新") {
                // Handled by active window
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
            Button("报告问题…") {
                if let url = URL(string: "https://github.com/macnev2013/macSCP/issues") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
