//
//  AppLockManager.swift
//  macSCP
//
//  Manages app lock state and biometric authentication preferences
//

import Foundation
import SwiftUI

enum InactivityTimeout: Int, CaseIterable, Sendable, Identifiable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .oneMinute: return "1 分钟"
        case .fiveMinutes: return "5 分钟"
        case .fifteenMinutes: return "15 分钟"
        case .thirtyMinutes: return "30 分钟"
        case .oneHour: return "1 小时"
        }
    }
}

@MainActor
@Observable
final class AppLockManager {
    static let shared = AppLockManager()

    // MARK: - State

    private(set) var isLocked = false
    private(set) var isAuthenticating = false
    private(set) var authenticationError: String?

    // MARK: - Preferences (stored, synced to UserDefaults)

    private(set) var isBiometricLockEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isBiometricLockEnabled, forKey: Keys.biometricLockEnabled)
            if !isBiometricLockEnabled {
                isLocked = false
                authenticationError = nil
                cancelInactivityTimer()
            } else {
                resetInactivityTimer()
            }
        }
    }

    var lockOnAppResume: Bool = false {
        didSet { UserDefaults.standard.set(lockOnAppResume, forKey: Keys.lockOnAppResume) }
    }

    var lockBeforeConnection: Bool = false {
        didSet { UserDefaults.standard.set(lockBeforeConnection, forKey: Keys.lockBeforeConnection) }
    }

    var lockAfterInactivity: Bool = false {
        didSet {
            UserDefaults.standard.set(lockAfterInactivity, forKey: Keys.lockAfterInactivity)
            if lockAfterInactivity {
                resetInactivityTimer()
            } else {
                cancelInactivityTimer()
            }
        }
    }

    var inactivityTimeout: InactivityTimeout = .fiveMinutes {
        didSet {
            UserDefaults.standard.set(inactivityTimeout.rawValue, forKey: Keys.inactivityTimeout)
            resetInactivityTimer()
        }
    }

    // MARK: - Dependencies

    private let biometricService: BiometricAuthServiceProtocol
    @ObservationIgnored private var backgroundObserver: Any?
    @ObservationIgnored private var activityObserver: Any?
    @ObservationIgnored private var inactivityTimer: Timer?

    // MARK: - Constants

    private enum Keys {
        static let biometricLockEnabled = "com.macSCP.biometricLockEnabled"
        static let lockOnAppResume = "com.macSCP.lockOnAppResume"
        static let lockBeforeConnection = "com.macSCP.lockBeforeConnection"
        static let lockAfterInactivity = "com.macSCP.lockAfterInactivity"
        static let inactivityTimeout = "com.macSCP.inactivityTimeout"
    }

    // MARK: - Initialization

    private init(biometricService: BiometricAuthServiceProtocol = BiometricAuthService.shared) {
        self.biometricService = biometricService

        // Load persisted preferences (didSet not called during init)
        self.isBiometricLockEnabled = UserDefaults.standard.bool(forKey: Keys.biometricLockEnabled)
        self.lockOnAppResume = UserDefaults.standard.bool(forKey: Keys.lockOnAppResume)
        self.lockBeforeConnection = UserDefaults.standard.bool(forKey: Keys.lockBeforeConnection)
        self.lockAfterInactivity = UserDefaults.standard.bool(forKey: Keys.lockAfterInactivity)
        let rawTimeout = UserDefaults.standard.integer(forKey: Keys.inactivityTimeout)
        self.inactivityTimeout = InactivityTimeout(rawValue: rawTimeout) ?? .fiveMinutes

        setupObservers()
    }

    // MARK: - Public Methods

    /// Called on app launch to lock if enabled
    func lockIfNeeded() {
        guard isBiometricLockEnabled else { return }
        isLocked = true
        authenticationError = nil
        logInfo("App locked on launch", category: .auth)
    }

    /// Attempt to unlock the app
    func unlock() {
        Task { @MainActor in
            let success = await performAuthentication(reason: "解锁 MiniShell")
            if success {
                resetInactivityTimer()
            }
        }
    }

    /// Authenticate before a connection attempt. Returns true if allowed.
    func authenticateForConnection() async -> Bool {
        guard isBiometricLockEnabled, lockBeforeConnection else {
            return true
        }

        logInfo("Authenticating for connection", category: .auth)
        let success = await performAuthentication(reason: "连接服务器前验证身份")
        if success {
            resetInactivityTimer()
        }
        return success
    }

    /// Enable biometric lock (no auth needed to enable)
    func enableBiometricLock() {
        isBiometricLockEnabled = true
        logInfo("Biometric lock enabled", category: .auth)
    }

    /// Disable biometric lock (requires authentication first)
    /// Returns true if the lock was successfully disabled.
    @discardableResult
    func disableBiometricLock() async -> Bool {
        let success = await performAuthentication(reason: "关闭触控 ID 锁定前验证身份")
        guard success else {
            logInfo("Biometric lock disable denied: auth failed", category: .auth)
            return false
        }
        isBiometricLockEnabled = false
        logInfo("Biometric lock disabled after authentication", category: .auth)
        return true
    }

    /// Record user activity to reset the inactivity timer
    func recordActivity() {
        guard isBiometricLockEnabled, lockAfterInactivity, !isLocked else { return }
        resetInactivityTimer()
    }

    // MARK: - Private Methods

    @discardableResult
    private func performAuthentication(reason: String) async -> Bool {
        guard !isAuthenticating else { return false }

        isAuthenticating = true
        authenticationError = nil

        let result = await biometricService.authenticate(reason: reason)

        isAuthenticating = false

        switch result {
        case .success:
            isLocked = false
            authenticationError = nil
            logInfo("Authentication succeeded", category: .auth)
            return true

        case .failure(let error):
            switch error {
            case .userCancelled:
                logInfo("Authentication cancelled by user", category: .auth)
            default:
                authenticationError = error.localizedDescription
                logWarning("Authentication failed: \(error.localizedDescription)", category: .auth)
            }
            return false
        }
    }

    private func lock(reason: String) {
        guard isBiometricLockEnabled, !isLocked else { return }
        isLocked = true
        authenticationError = nil
        cancelInactivityTimer()
        logInfo("App locked: \(reason)", category: .auth)
    }

    // MARK: - Inactivity Timer

    private func resetInactivityTimer() {
        cancelInactivityTimer()
        guard isBiometricLockEnabled, lockAfterInactivity, !isLocked else { return }

        let seconds = TimeInterval(inactivityTimeout.rawValue)
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.lock(reason: "inactivity timeout")
            }
        }
    }

    private func cancelInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    // MARK: - Observers

    private func setupObservers() {
        // Lock when app goes to background (if enabled)
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.lockOnAppResume {
                    self.lock(reason: "app went to background")
                }
            }
        }

        // Reset inactivity timer on user interaction
        activityObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordActivity()
            }
        }
    }
}
