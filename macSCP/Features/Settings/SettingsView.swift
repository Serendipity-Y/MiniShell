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
    @AppStorage(TerminalAppearancePreferences.windowWidthKey)
    private var terminalWindowWidth = TerminalAppearancePreferences.defaultWindowWidth
    @AppStorage(TerminalAppearancePreferences.windowHeightKey)
    private var terminalWindowHeight = TerminalAppearancePreferences.defaultWindowHeight
    @AppStorage(TerminalAppearancePreferences.fontSizeKey)
    private var terminalFontSize = TerminalAppearancePreferences.defaultFontSize
    @AppStorage(TerminalAppearancePreferences.foregroundColorKey)
    private var terminalForegroundColorHex = TerminalAppearancePreferences.defaultForegroundColor
    @AppStorage(TerminalAppearancePreferences.backgroundColorKey)
    private var terminalBackgroundColorHex = TerminalAppearancePreferences.defaultBackgroundColor

    private var isBiometricAvailable: Bool {
        biometricService.isBiometricAvailable()
    }

    private var isEnabled: Bool {
        appLockManager.isBiometricLockEnabled
    }

    var body: some View {
        Form {
            terminalAppearanceSection
            securitySection
        }
        .formStyle(.grouped)
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: terminalWindowWidth) { _, value in
            terminalWindowWidth = min(
                max(value, TerminalAppearancePreferences.windowWidthRange.lowerBound),
                TerminalAppearancePreferences.windowWidthRange.upperBound
            )
        }
        .onChange(of: terminalWindowHeight) { _, value in
            terminalWindowHeight = min(
                max(value, TerminalAppearancePreferences.windowHeightRange.lowerBound),
                TerminalAppearancePreferences.windowHeightRange.upperBound
            )
        }
        .onChange(of: terminalFontSize) { _, value in
            terminalFontSize = min(
                max(value, TerminalAppearancePreferences.fontSizeRange.lowerBound),
                TerminalAppearancePreferences.fontSizeRange.upperBound
            )
        }
    }

    // MARK: - Terminal Appearance

    private var terminalForegroundColor: Binding<Color> {
        Binding(
            get: {
                TerminalAppearancePreferences.color(
                    from: terminalForegroundColorHex,
                    fallback: TerminalAppearancePreferences.defaultForegroundColor
                )
            },
            set: { color in
                terminalForegroundColorHex = TerminalAppearancePreferences.hexString(
                    from: color,
                    fallback: TerminalAppearancePreferences.defaultForegroundColor
                )
            }
        )
    }

    private var terminalBackgroundColor: Binding<Color> {
        Binding(
            get: {
                TerminalAppearancePreferences.color(
                    from: terminalBackgroundColorHex,
                    fallback: TerminalAppearancePreferences.defaultBackgroundColor
                )
            },
            set: { color in
                terminalBackgroundColorHex = TerminalAppearancePreferences.hexString(
                    from: color,
                    fallback: TerminalAppearancePreferences.defaultBackgroundColor
                )
            }
        )
    }

    @ViewBuilder
    private var terminalAppearanceSection: some View {
        Section {
            HStack {
                Text("默认窗口大小")
                Spacer()
                TextField("宽度", value: $terminalWindowWidth, format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 72)
                Text("×")
                    .foregroundStyle(.secondary)
                TextField("高度", value: $terminalWindowHeight, format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 72)
                Text("点")
                    .foregroundStyle(.secondary)
            }

            Stepper(value: $terminalFontSize, in: TerminalAppearancePreferences.fontSizeRange, step: 1) {
                LabeledContent("字体大小") {
                    Text("\(Int(terminalFontSize)) 点")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            ColorPicker("字体颜色", selection: terminalForegroundColor, supportsOpacity: false)
            ColorPicker("背景颜色", selection: terminalBackgroundColor, supportsOpacity: false)

            terminalPreview

            HStack {
                Spacer()
                Button("恢复默认") {
                    resetTerminalAppearance()
                }
            }
        } header: {
            Text("终端外观")
        } footer: {
            Text("字体和颜色会立即作用于已打开的终端；窗口大小会在下次新建主窗口或独立终端窗口时生效。")
        }
    }

    private var terminalPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("suchfool@MiniShell:~$ ssh 服务器")
            Text("终端外观预览")
        }
        .font(.system(size: terminalFontSize, design: .monospaced))
        .foregroundStyle(terminalForegroundColor.wrappedValue)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(12)
        .background(terminalBackgroundColor.wrappedValue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func resetTerminalAppearance() {
        terminalWindowWidth = TerminalAppearancePreferences.defaultWindowWidth
        terminalWindowHeight = TerminalAppearancePreferences.defaultWindowHeight
        terminalFontSize = TerminalAppearancePreferences.defaultFontSize
        terminalForegroundColorHex = TerminalAppearancePreferences.defaultForegroundColor
        terminalBackgroundColorHex = TerminalAppearancePreferences.defaultBackgroundColor
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
