//
//  ConnectionFormSheet.swift
//  macSCP
//
//  Form for creating and editing connections
//

import SwiftUI

enum ConnectionFormMode {
    case create
    case edit(Connection)

    var title: String {
        switch self {
        case .create: return "新建连接"
        case .edit: return "编辑连接"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .create: return "创建"
        case .edit: return "保存"
        }
    }
}

struct ConnectionFormSheet: View {
    let mode: ConnectionFormMode
    let savedPassword: String?
    let folders: [Folder]
    let onSave: (Connection, String?) -> Void
    let onCancel: () -> Void

    // Form fields
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var authMethod: AuthMethod = .password
    @State private var privateKeyPath: String = ""
    @State private var savePassword: Bool = false
    @State private var password: String = ""
    @State private var description: String = ""
    @State private var iconName: String = "server.rack"
    @State private var selectedFolderId: UUID?
    @State private var tags: [String] = []
    @State private var newTag: String = ""

    init(
        mode: ConnectionFormMode,
        savedPassword: String? = nil,
        folders: [Folder] = [],
        onSave: @escaping (Connection, String?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = mode
        self.savedPassword = savedPassword
        self.folders = folders
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(mode.title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()

            Divider()

            Form {
                Section("连接") {
                    TextField("名称", text: $name)
                    TextField("主机", text: $host)
                    TextField("端口", text: $port)
                    TextField("用户名", text: $username)
                }

                Section("身份验证") {
                    Picker("方式", selection: $authMethod) {
                        ForEach(AuthMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    if authMethod == .password {
                        SecureField("密码", text: $password)
                        Toggle("将密码保存到钥匙串", isOn: $savePassword)
                    } else {
                        HStack {
                            TextField("私钥路径", text: $privateKeyPath)
                            Button("选择") {
                                browseForKey()
                            }
                        }
                    }
                }

                // Organization
                Section("整理") {
                    Picker("文件夹", selection: $selectedFolderId) {
                        Text("无").tag(nil as UUID?)
                        ForEach(folders) { folder in
                            Text(folder.name).tag(folder.id as UUID?)
                        }
                    }

                    // Tags
                    LabeledContent("标签") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("", text: $newTag)
                                    .onSubmit {
                                        addTag()
                                    }
                                Button {
                                    addTag()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(newTag.trimmed.isEmpty ? Color.gray : Color.blue)
                                }
                                .buttonStyle(.plain)
                                .disabled(newTag.trimmed.isEmpty)
                            }

                            if !tags.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(tags, id: \.self) { tag in
                                        TagChip(tag: tag) {
                                            removeTag(tag)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Optional
                Section("可选") {
                    TextField("备注", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    IconPickerRow(selectedIcon: $iconName)
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Button(mode.saveButtonTitle) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 500, height: 580)
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmed.isEmpty &&
            !host.trimmed.isEmpty &&
            !username.trimmed.isEmpty &&
            (Int(port) ?? 0) > 0 && (Int(port) ?? 0) <= 65535 &&
            (authMethod == .password || !privateKeyPath.trimmed.isEmpty)
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        if case .edit(let connection) = mode {
            name = connection.name
            host = connection.host
            port = String(connection.port)
            username = connection.username
            authMethod = connection.authMethod
            privateKeyPath = connection.privateKeyPath ?? ""
            savePassword = connection.savePassword
            description = connection.description ?? ""
            iconName = connection.iconName
            selectedFolderId = connection.folderId
            tags = connection.tags
            password = savedPassword ?? ""
        }
    }

    // MARK: - Save

    private func save() {
        let portNumber = Int(port) ?? 22

        let connection: Connection
        if case .edit(let existing) = mode {
            connection = Connection(
                id: existing.id,
                name: name.trimmed,
                host: host.trimmed,
                port: portNumber,
                username: username.trimmed,
                authMethod: authMethod,
                privateKeyPath: authMethod == .privateKey ? privateKeyPath.trimmed : nil,
                savePassword: savePassword,
                description: description.trimmed.isEmpty ? nil : description.trimmed,
                tags: tags,
                iconName: iconName,
                folderId: selectedFolderId,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else {
            connection = Connection(
                name: name.trimmed,
                host: host.trimmed,
                port: portNumber,
                username: username.trimmed,
                authMethod: authMethod,
                privateKeyPath: authMethod == .privateKey ? privateKeyPath.trimmed : nil,
                savePassword: savePassword,
                description: description.trimmed.isEmpty ? nil : description.trimmed,
                tags: tags,
                iconName: iconName,
                folderId: selectedFolderId
            )
        }

        let passwordToSave = savePassword && !password.isEmpty ? password : nil
        onSave(connection, passwordToSave)
    }

    // MARK: - Helpers

    private func browseForKey() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")

        if panel.runModal() == .OK, let url = panel.url {
            privateKeyPath = url.path
        }
    }

    private func addTag() {
        let tag = newTag.trimmed
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

// MARK: - Icon Picker Row
struct IconPickerRow: View {
    @Binding var selectedIcon: String
    @State private var showingIconSelector = false

    var body: some View {
        HStack {
            Text("图标")
            Spacer()
            Button {
                showingIconSelector.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(selectedIcon)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingIconSelector, arrowEdge: .trailing) {
                IconSelectorView(selectedIcon: $selectedIcon)
            }
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isHovering ? .red : .primary)

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(isHovering ? AnyShapeStyle(.red) : AnyShapeStyle(.tertiary))
        }
        .padding(.leading, 8)
        .padding(.trailing, 5)
        .padding(.vertical, 3)
        .background(.fill.tertiary, in: Capsule())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onRemove()
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
#Preview("Create") {
    ConnectionFormSheet(
        mode: .create,
        folders: [
            Folder(name: "Production"),
            Folder(name: "Development")
        ],
        onSave: { _, _ in },
        onCancel: {}
    )
}

#Preview("Edit") {
    ConnectionFormSheet(
        mode: .edit(Connection(
            name: "Test Server",
            host: "test.example.com",
            username: "admin",
            tags: ["production", "critical"]
        )),
        savedPassword: "secret123",
        folders: [
            Folder(name: "Production"),
            Folder(name: "Development")
        ],
        onSave: { _, _ in },
        onCancel: {}
    )
}
