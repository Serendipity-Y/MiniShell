//
//  ConnectionDetailView.swift
//  macSCP
//
//  Detail panel showing connection info — Apple Contacts style
//

import SwiftUI

struct ConnectionDetailView: View {
    let connection: Connection
    let onConnect: () -> Void
    let onOpenTerminal: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    private let iconColor = Color.blue

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Avatar + Name (Contacts-style header)
                headerSection

                // Quick action buttons row (like Contacts' message/call/video/mail)
                quickActionsRow

                // Grouped detail cards
                detailCards

                // Footer metadata
                footerSection
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: onEdit) {
                    Text("编辑")
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: connection.iconName)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(iconColor)
                .frame(width: 80, height: 80)

            // Name
            Text(connection.name)
                .font(.system(size: 22, weight: .bold))

            Text("SSH / SFTP 连接")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Actions Row

    private var quickActionsRow: some View {
        HStack(spacing: 16) {
            // Open Files
            ContactActionButton(
                icon: "folder.fill",
                label: "文件",
                action: onConnect
            )

            ContactActionButton(
                icon: "terminal.fill",
                label: "终端",
                action: onOpenTerminal
            )

            // Duplicate
            ContactActionButton(
                icon: "doc.on.doc",
                label: "复制",
                action: onDuplicate
            )

            // Delete
            ContactActionButton(
                icon: "trash",
                label: "删除",
                isDestructive: true,
                action: onDelete
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Detail Cards

    private var detailCards: some View {
        VStack(spacing: 12) {
            sftpCard

            // Tags card
            if !connection.tags.isEmpty {
                tagsCard
            }

            // Notes card
            if let description = connection.description, !description.isEmpty {
                notesCard(description)
            }
        }
    }

    private var sftpCard: some View {
        GroupBox {
            VStack(spacing: 0) {
                contactDetailRow(label: "主机", value: connection.host, icon: "globe")
                Divider().padding(.leading, 36)
                contactDetailRow(label: "端口", value: "\(connection.port)", icon: "number")
                Divider().padding(.leading, 36)
                contactDetailRow(label: "用户名", value: connection.username, icon: "person")
                Divider().padding(.leading, 36)
                contactDetailRow(label: "验证方式", value: connection.authMethod.displayName, icon: "key")
                if connection.authMethod == .privateKey, let keyPath = connection.privateKeyPath {
                    Divider().padding(.leading, 36)
                    contactDetailRow(label: "私钥路径", value: keyPath, icon: "doc.text")
                }
            }
        }
    }

    private var tagsCard: some View {
        GroupBox {
            HStack(alignment: .top) {
                Image(systemName: "tag")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("标签")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    FlowLayout(spacing: 6) {
                        ForEach(connection.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.fill.tertiary, in: Capsule())
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func notesCard(_ text: String) -> some View {
        GroupBox {
            HStack(alignment: .top) {
                Image(systemName: "note.text")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text("备注")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(text)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Detail Row

    private func contactDetailRow(label: String, value: String, icon: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 2) {
            Text("创建于 \(connection.createdAt.formatted(date: .abbreviated, time: .shortened))")
            Text("更新于 \(connection.updatedAt.formatted(date: .abbreviated, time: .shortened))")
        }
        .font(.system(size: 11))
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - Contact Action Button

private struct ContactActionButton: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 44, height: 44)
                    .background(.quaternary, in: Circle())

                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(isDestructive ? .red : .primary)
        }
        .buttonStyle(.plain)
    }
}
