//
//  TerminalWorkspaceView.swift
//  macSCP
//
//  In-window terminal tabs for the main session workspace
//

import SwiftUI
import AppKit

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

    func selectTerminal(id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        selectedTabID = id
    }

    func duplicateTerminal(id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        openTerminal(with: tab.data)
    }
}

struct TerminalWorkspaceView: View {
    @Bindable var workspace: TerminalWorkspaceViewModel
    let onOpenSFTP: (TerminalWindowData) -> Void
    private let tabBarHeight: CGFloat = 52

    var body: some View {
        ZStack(alignment: .top) {
            if let selectedTab {
                TerminalContentView(
                    viewModel: selectedTab.viewModel,
                    onOpenSFTP: { onOpenSFTP(selectedTab.data) },
                    disconnectOnDisappear: false,
                    showsToolbar: false,
                    isActive: true
                )
                .id(selectedTab.id)
                .zIndex(0)
                .padding(.top, tabBarHeight)
            }

            VStack(spacing: 0) {
                TerminalTabStrip(
                    items: workspace.tabs.map { tab in
                        TerminalTabStripItem(
                            id: tab.id,
                            title: tab.title,
                            statusColor: statusColor(for: tab.viewModel)
                        )
                    },
                    selectedTabID: workspace.selectedTabID,
                    onSelect: workspace.selectTerminal,
                    onClose: workspace.closeTerminal,
                    onDuplicate: workspace.duplicateTerminal
                )
                .frame(height: tabBarHeight - 1)
                Divider()
            }
            .zIndex(1)
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

    private func statusColor(for viewModel: TerminalViewModel) -> NSColor {
        switch viewModel.state {
        case .connected:
            return .systemGreen
        case .connecting:
            return .systemOrange
        case .disconnected, .error:
            return .secondaryLabelColor
        }
    }

    private var selectedTab: TerminalTab? {
        workspace.tabs.first { $0.id == workspace.selectedTabID }
    }

}

private struct TerminalTabStripItem {
    let id: UUID
    let title: String
    let statusColor: NSColor
}

private struct TerminalTabStrip: NSViewRepresentable {
    let items: [TerminalTabStripItem]
    let selectedTabID: UUID?
    let onSelect: (UUID) -> Void
    let onClose: (UUID) -> Void
    let onDuplicate: (UUID) -> Void

    func makeNSView(context: Context) -> TerminalTabStripScrollView {
        let view = TerminalTabStripScrollView()
        view.update(
            items: items,
            selectedTabID: selectedTabID,
            onSelect: onSelect,
            onClose: onClose,
            onDuplicate: onDuplicate
        )
        return view
    }

    func updateNSView(_ nsView: TerminalTabStripScrollView, context: Context) {
        nsView.update(
            items: items,
            selectedTabID: selectedTabID,
            onSelect: onSelect,
            onClose: onClose,
            onDuplicate: onDuplicate
        )
    }
}

private final class TerminalTabStripScrollView: NSScrollView {
    private let canvas = TerminalTabStripCanvas()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        drawsBackground = false
        hasHorizontalScroller = false
        hasVerticalScroller = false
        autohidesScrollers = true
        horizontalScrollElasticity = .allowed
        verticalScrollElasticity = .none
        documentView = canvas
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        canvas.updateLayout(minimumWidth: contentView.bounds.width)
    }

    func update(
        items: [TerminalTabStripItem],
        selectedTabID: UUID?,
        onSelect: @escaping (UUID) -> Void,
        onClose: @escaping (UUID) -> Void,
        onDuplicate: @escaping (UUID) -> Void
    ) {
        canvas.update(
            items: items,
            selectedTabID: selectedTabID,
            onSelect: onSelect,
            onClose: onClose,
            onDuplicate: onDuplicate,
            minimumWidth: contentView.bounds.width
        )
    }
}

private final class TerminalTabStripCanvas: NSView {
    private struct ItemFrame {
        let item: TerminalTabStripItem
        let frame: CGRect

        var closeFrame: CGRect {
            CGRect(x: frame.maxX - 30, y: frame.minY, width: 30, height: frame.height)
        }
    }

    private let tabHeight: CGFloat = 36
    private var items: [TerminalTabStripItem] = []
    private var selectedTabID: UUID?
    private var itemFrames: [ItemFrame] = []
    private var hoveredTabID: UUID?
    private var consumesClick = false
    private var eventMonitor: Any?
    private var contextTabID: UUID?

    private var onSelect: ((UUID) -> Void)?
    private var onClose: ((UUID) -> Void)?
    private var onDuplicate: ((UUID) -> Void)?

    override var isFlipped: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installEventMonitor()
    }

    deinit {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    func update(
        items: [TerminalTabStripItem],
        selectedTabID: UUID?,
        onSelect: @escaping (UUID) -> Void,
        onClose: @escaping (UUID) -> Void,
        onDuplicate: @escaping (UUID) -> Void,
        minimumWidth: CGFloat
    ) {
        self.items = items
        self.selectedTabID = selectedTabID
        self.onSelect = onSelect
        self.onClose = onClose
        self.onDuplicate = onDuplicate
        updateLayout(minimumWidth: minimumWidth)
    }

    func updateLayout(minimumWidth: CGFloat) {
        let font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        var nextX: CGFloat = 10
        itemFrames = items.map { item in
            let textWidth = ceil((item.title as NSString).size(withAttributes: attributes).width)
            let frame = CGRect(x: nextX, y: 8, width: textWidth + 74, height: tabHeight)
            nextX = frame.maxX + 4
            return ItemFrame(item: item, frame: frame)
        }

        let width = max(minimumWidth, nextX + 10)
        if frame.size != CGSize(width: width, height: 51) {
            frame.size = CGSize(width: width, height: 51)
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        for itemFrame in itemFrames where dirtyRect.intersects(itemFrame.frame) {
            draw(itemFrame)
        }
    }

    private func draw(_ itemFrame: ItemFrame) {
        let isSelected = itemFrame.item.id == selectedTabID
        let isHovered = itemFrame.item.id == hoveredTabID
        let path = NSBezierPath(roundedRect: itemFrame.frame, xRadius: 7, yRadius: 7)

        if isSelected || isHovered {
            NSGraphicsContext.saveGraphicsState()
            if isHovered {
                NSGraphicsContext.current?.cgContext.setShadow(
                    offset: CGSize(width: 0, height: -2),
                    blur: 5,
                    color: NSColor.black.withAlphaComponent(0.28).cgColor
                )
            }
            let fillColor: NSColor
            if isSelected {
                fillColor = NSColor.controlAccentColor.withAlphaComponent(isHovered ? 0.34 : 0.24)
            } else {
                fillColor = NSColor.white.withAlphaComponent(0.15)
            }
            fillColor.setFill()
            path.fill()
            NSGraphicsContext.restoreGraphicsState()
        }

        if isHovered {
            (isSelected ? NSColor.controlAccentColor.withAlphaComponent(0.8) : NSColor.white.withAlphaComponent(0.24)).setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        let dotFrame = CGRect(x: itemFrame.frame.minX + 16, y: itemFrame.frame.midY - 3.5, width: 7, height: 7)
        itemFrame.item.statusColor.setFill()
        NSBezierPath(ovalIn: dotFrame).fill()

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        let textFrame = CGRect(
            x: itemFrame.frame.minX + 30,
            y: itemFrame.frame.midY - 9,
            width: itemFrame.closeFrame.minX - itemFrame.frame.minX - 34,
            height: 18
        )
        (itemFrame.item.title as NSString).draw(in: textFrame, withAttributes: textAttributes)

        let closeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 19, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let closeTextFrame = CGRect(x: itemFrame.closeFrame.midX - 7, y: itemFrame.frame.midY - 11, width: 14, height: 22)
        ("×" as NSString).draw(in: closeTextFrame, withAttributes: closeAttributes)
    }

    private func installEventMonitor() {
        guard eventMonitor == nil else { return }
        window?.acceptsMouseMovedEvents = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .leftMouseUp, .rightMouseDown]
        ) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            return self.handle(event)
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        let point = convert(event.locationInWindow, from: nil)
        let hitItem = itemFrames.first { $0.frame.contains(point) }

        switch event.type {
        case .mouseMoved:
            setHoveredTab(hitItem?.item.id)
            return event

        case .leftMouseDown:
            guard let hitItem else { return event }
            consumesClick = true
            if hitItem.closeFrame.contains(point) {
                onClose?(hitItem.item.id)
            } else {
                onSelect?(hitItem.item.id)
            }
            return nil

        case .leftMouseUp:
            guard consumesClick else { return event }
            consumesClick = false
            return nil

        case .rightMouseDown:
            guard let hitItem else { return event }
            contextTabID = hitItem.item.id
            showContextMenu(at: point)
            return nil

        default:
            return event
        }
    }

    private func setHoveredTab(_ id: UUID?) {
        guard hoveredTabID != id else { return }
        hoveredTabID = id
        needsDisplay = true
    }

    private func showContextMenu(at point: CGPoint) {
        let menu = NSMenu()

        let duplicate = NSMenuItem(title: "复制会话", action: #selector(duplicateContextTab), keyEquivalent: "")
        duplicate.target = self
        menu.addItem(duplicate)
        menu.addItem(.separator())

        let close = NSMenuItem(title: "关闭终端", action: #selector(closeContextTab), keyEquivalent: "")
        close.target = self
        menu.addItem(close)

        menu.popUp(positioning: nil, at: point, in: self)
    }

    @objc private func duplicateContextTab() {
        if let contextTabID {
            onDuplicate?(contextTabID)
        }
    }

    @objc private func closeContextTab() {
        if let contextTabID {
            onClose?(contextTabID)
        }
    }
}
