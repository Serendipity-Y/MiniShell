//
//  SettingsView.swift
//  macSCP
//
//  Application settings view (Cmd+, shortcut via Settings scene)
//

import SwiftUI

struct SettingsView: View {
    @State private var appLockManager = AppLockManager.shared
    private let biometricService: BiometricAuthServiceProtocol = BiometricAuthService.shared

    private var isBiometricAvailable: Bool {
        biometricService.isBiometricAvailable()
    }

    private var isEnabled: Bool {
        appLockManager.isBiometricLockEnabled
    }

    var body: some View {
        Form {
            securitySection
        }
        .formStyle(.grouped)
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Security Section

    @ViewBuilder
    private var securitySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { appLockManager.isBiometricLockEnabled },
                set: { newValue in
                    if newValue {
                        appLockManager.enableBiometricLock()
                    } else {
                        Task {
                            await appLockManager.disableBiometricLock()
                        }
                    }
                }
            )) {
                Label("要求使用触控 ID", systemImage: "touchid")
            }
            .disabled(!isBiometricAvailable)

            if !isBiometricAvailable {
                Text("此 Mac 不支持触控 ID。请使用支持触控 ID 的 Mac，或配对 Apple Watch 后启用此功能。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isEnabled {
                Toggle(isOn: Bindable(appLockManager).lockOnAppResume) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("切换应用时锁定")
                        Text("返回 MiniShell 时要求验证")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: Bindable(appLockManager).lockBeforeConnection) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("每次连接前要求验证")
                        Text("连接任何服务器前先完成验证")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Toggle(isOn: Bindable(appLockManager).lockAfterInactivity) {
                        Text("闲置后锁定")
                    }

                    Spacer()

                    Picker("", selection: Bindable(appLockManager).inactivityTimeout) {
                        ForEach(InactivityTimeout.allCases) { timeout in
                            Text(timeout.label).tag(timeout)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(!appLockManager.lockAfterInactivity)
                }
            }
        } header: {
            Text("安全")
        } footer: {
            if isEnabled {
                Text("应用启动时始终要求验证。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
