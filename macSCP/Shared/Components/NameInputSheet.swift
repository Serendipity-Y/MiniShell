//
//  NameInputSheet.swift
//  macSCP
//
//  Reusable name input sheet for creating/renaming items
//

import SwiftUI

struct NameInputSheet: View {
    let title: String
    let message: String
    let placeholder: String
    let confirmButtonTitle: String
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        message: String = "",
        placeholder: String = "名称",
        initialValue: String = "",
        confirmButtonTitle: String = "创建",
        onConfirm: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.placeholder = placeholder
        self.confirmButtonTitle = confirmButtonTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self._name = State(initialValue: initialValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.spacing) {
            Text(title)
                .font(.headline)

            if !message.isEmpty {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            TextField(placeholder, text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if isValid {
                        onConfirm(name.trimmed)
                    }
                }

            HStack {
                Spacer()

                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button(confirmButtonTitle) {
                    onConfirm(name.trimmed)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            isFocused = true
        }
    }

    private var isValid: Bool {
        !name.trimmed.isEmpty
    }
}

// MARK: - Preset Sheets
extension NameInputSheet {
    static func newFolder(onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) -> NameInputSheet {
        NameInputSheet(
            title: "新建文件夹",
            message: "请输入新文件夹名称。",
            placeholder: "文件夹名称",
            confirmButtonTitle: "创建",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    static func newFile(onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) -> NameInputSheet {
        NameInputSheet(
            title: "新建文件",
            message: "请输入新文件名称。",
            placeholder: "文件名称",
            confirmButtonTitle: "创建",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    static func rename(
        currentName: String,
        onConfirm: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) -> NameInputSheet {
        NameInputSheet(
            title: "重命名",
            message: "请输入新名称。",
            placeholder: "名称",
            initialValue: currentName,
            confirmButtonTitle: "重命名",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

// MARK: - Preview
#Preview("Name Input") {
    NameInputSheet(
        title: "New Folder",
        message: "Enter a name for the new folder.",
        placeholder: "Folder name",
        onConfirm: { _ in },
        onCancel: {}
    )
}

#Preview("Rename") {
    NameInputSheet.rename(
        currentName: "Documents",
        onConfirm: { _ in },
        onCancel: {}
    )
}
