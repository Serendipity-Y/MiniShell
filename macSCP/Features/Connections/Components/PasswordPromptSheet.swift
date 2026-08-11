//
//  PasswordPromptSheet.swift
//  macSCP
//
//  Password prompt for connecting to a server
//

import SwiftUI

struct PasswordPromptSheet: View {
    let connectionName: String
    let onConnect: (String) -> Void
    let onCancel: () -> Void

    @State private var password: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: UIConstants.spacing) {
            Image(systemName: "key.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("输入密码")
                .font(.headline)

            Text("请输入“\(connectionName)”的密码")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if !password.isEmpty {
                        onConnect(password)
                    }
                }

            HStack {
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("连接") {
                    onConnect(password)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty)
            }
        }
        .padding(UIConstants.spacing * 2)
        .frame(width: 300)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Preview
#Preview {
    PasswordPromptSheet(
        connectionName: "Production Server",
        onConnect: { _ in },
        onCancel: {}
    )
}
