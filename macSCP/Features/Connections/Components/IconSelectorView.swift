//
//  IconSelectorView.swift
//  macSCP
//
//  Icon selector with categorized SF Symbols for connections
//

import SwiftUI

struct IconSelectorView: View {
    @Binding var selectedIcon: String
    @State private var searchText: String = ""
    @State private var selectedCategory: IconCategory = .servers

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索图标…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.top, 12)

            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(IconCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)

            Divider()

            // Icons grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        IconCell(
                            icon: icon,
                            isSelected: selectedIcon == icon
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedIcon = icon
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Selected icon preview
            HStack {
                Text("已选择：")
                    .foregroundStyle(.secondary)
                Image(systemName: selectedIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text(selectedIcon)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
        }
        .frame(width: 380, height: 420)
    }

    private var filteredIcons: [String] {
        let icons = searchText.isEmpty ? selectedCategory.icons : allIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }
        return icons
    }

    private var allIcons: [String] {
        IconCategory.allCases.flatMap { $0.icons }
    }
}

// MARK: - Category Tab
private struct CategoryTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay {
                if !isSelected {
                    Capsule()
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Cell
private struct IconCell: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 44, height: 44)
                .foregroundStyle(isSelected ? .white : (isHovering ? .blue : .primary))
                .background(isSelected ? Color.blue : (isHovering ? Color.blue.opacity(0.1) : Color.clear))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.blue : (isHovering ? Color.blue.opacity(0.3) : Color.clear), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Icon Categories
enum IconCategory: CaseIterable {
    case servers
    case devices
    case network
    case cloud
    case storage
    case security
    case development
    case misc

    var displayName: String {
        switch self {
        case .servers: return "服务器"
        case .devices: return "设备"
        case .network: return "网络"
        case .cloud: return "云端"
        case .storage: return "存储"
        case .security: return "安全"
        case .development: return "开发"
        case .misc: return "其他"
        }
    }

    var icon: String {
        switch self {
        case .servers: return "server.rack"
        case .devices: return "desktopcomputer"
        case .network: return "network"
        case .cloud: return "cloud"
        case .storage: return "externaldrive"
        case .security: return "lock.shield"
        case .development: return "hammer"
        case .misc: return "square.grid.2x2"
        }
    }

    var icons: [String] {
        switch self {
        case .servers:
            return [
                "server.rack",
                "xserve",
                "macpro.gen1",
                "macpro.gen2",
                "macpro.gen3",
                "cpu",
                "cpu.fill",
                "memorychip",
                "memorychip.fill",
                "terminal",
                "terminal.fill",
                "text.and.command.macwindow",
                "rectangle.on.rectangle.badge.gearshape"
            ]
        case .devices:
            return [
                "desktopcomputer",
                "pc",
                "display",
                "display.2",
                "laptopcomputer",
                "macbook",
                "macmini",
                "macstudio",
                "macmini.fill",
                "macstudio.fill",
                "ipad",
                "ipad.landscape",
                "iphone",
                "applewatch",
                "homepod",
                "homepod.mini",
                "hifispeaker",
                "tv",
                "tv.inset.filled",
                "appletv",
                "appletv.fill"
            ]
        case .network:
            return [
                "network",
                "globe",
                "globe.americas",
                "globe.europe.africa",
                "globe.asia.australia",
                "wifi",
                "wifi.router",
                "antenna.radiowaves.left.and.right",
                "dot.radiowaves.left.and.right",
                "wave.3.left",
                "wave.3.right",
                "point.3.connected.trianglepath.dotted",
                "point.3.filled.connected.trianglepath.dotted",
                "cable.connector",
                "cable.connector.horizontal",
                "arrow.left.arrow.right",
                "arrow.up.arrow.down",
                "link",
                "personalhotspot"
            ]
        case .cloud:
            return [
                "cloud",
                "cloud.fill",
                "icloud",
                "icloud.fill",
                "arrow.up.icloud",
                "arrow.up.icloud.fill",
                "arrow.down.icloud",
                "arrow.down.icloud.fill",
                "icloud.and.arrow.up",
                "icloud.and.arrow.up.fill",
                "icloud.and.arrow.down",
                "icloud.and.arrow.down.fill",
                "cloud.bolt",
                "cloud.bolt.fill",
                "cloud.sun",
                "cloud.sun.fill"
            ]
        case .storage:
            return [
                "externaldrive",
                "externaldrive.fill",
                "externaldrive.connected.to.line.below",
                "externaldrive.connected.to.line.below.fill",
                "internaldrive",
                "internaldrive.fill",
                "opticaldiscdrive",
                "opticaldiscdrive.fill",
                "sdcard",
                "sdcard.fill",
                "archivebox",
                "archivebox.fill",
                "cylinder",
                "cylinder.fill",
                "cylinder.split.1x2",
                "cylinder.split.1x2.fill",
                "doc",
                "doc.fill",
                "folder",
                "folder.fill"
            ]
        case .security:
            return [
                "lock",
                "lock.fill",
                "lock.open",
                "lock.open.fill",
                "lock.shield",
                "lock.shield.fill",
                "key",
                "key.fill",
                "key.horizontal",
                "key.horizontal.fill",
                "shield",
                "shield.fill",
                "shield.lefthalf.filled",
                "checkmark.shield",
                "checkmark.shield.fill",
                "xmark.shield",
                "xmark.shield.fill",
                "person.badge.key",
                "person.badge.key.fill",
                "touchid",
                "faceid"
            ]
        case .development:
            return [
                "hammer",
                "hammer.fill",
                "wrench.and.screwdriver",
                "wrench.and.screwdriver.fill",
                "gearshape",
                "gearshape.fill",
                "gearshape.2",
                "gearshape.2.fill",
                "curlybraces",
                "chevron.left.forwardslash.chevron.right",
                "apple.terminal",
                "apple.terminal.fill",
                "swift",
                "tuningfork",
                "wand.and.stars",
                "wand.and.stars.inverse",
                "ant",
                "ant.fill",
                "ladybug",
                "ladybug.fill"
            ]
        case .misc:
            return [
                "star",
                "star.fill",
                "heart",
                "heart.fill",
                "bookmark",
                "bookmark.fill",
                "tag",
                "tag.fill",
                "flag",
                "flag.fill",
                "bell",
                "bell.fill",
                "bolt",
                "bolt.fill",
                "sparkle",
                "sparkles",
                "wand.and.rays",
                "rays",
                "building.2",
                "building.2.fill"
            ]
        }
    }
}

// MARK: - Preview
#Preview {
    IconSelectorView(selectedIcon: .constant("server.rack"))
}
