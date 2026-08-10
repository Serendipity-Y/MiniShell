//
//  KeychainService.swift
//  macSCP
//
//  Keychain implementation for secure password storage
//

import Foundation
import Security

final class KeychainService: KeychainServiceProtocol, @unchecked Sendable {
    static let shared = KeychainService()

    private let service = AppConstants.keychainService
    private let s3Service = AppConstants.keychainS3Service

    private init() {}

    func savePassword(_ password: String, for connectionId: UUID) throws {
        guard let passwordData = password.data(using: .utf8) else {
            throw AppError.keychainSaveFailed
        }

        // Delete any existing password first
        try? deletePassword(for: connectionId)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: connectionId.uuidString,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            logError("Keychain save failed with status: \(status)", category: .keychain)
            throw AppError.keychainSaveFailed
        }

        logDebug("Password saved for connection: \(connectionId)", category: .keychain)
    }

    func getPassword(for connectionId: UUID) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: connectionId.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }

        return password
    }

    func deletePassword(for connectionId: UUID) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: connectionId.uuidString
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            logError("Keychain delete failed with status: \(status)", category: .keychain)
            throw AppError.keychainDeleteFailed
        }

        logDebug("Password deleted for connection: \(connectionId)", category: .keychain)
    }

    func updatePassword(_ password: String, for connectionId: UUID) throws {
        guard let passwordData = password.data(using: .utf8) else {
            throw AppError.keychainSaveFailed
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: connectionId.uuidString
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist, create it
            try savePassword(password, for: connectionId)
            return
        }

        if status != errSecSuccess {
            logError("Keychain update failed with status: \(status)", category: .keychain)
            throw AppError.keychainSaveFailed
        }

        logDebug("Password updated for connection: \(connectionId)", category: .keychain)
    }

    func hasPassword(for connectionId: UUID) -> Bool {
        getPassword(for: connectionId) != nil
    }

    // MARK: - S3 Credentials

    func saveS3Credentials(_ credentials: S3Credentials, for connectionId: UUID) throws {
        guard let credentialsData = try? JSONEncoder().encode(credentials) else {
            throw AppError.keychainSaveFailed
        }

        // Delete any existing credentials first
        try? deleteS3Credentials(for: connectionId)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: s3Service,
            kSecAttrAccount as String: connectionId.uuidString,
            kSecValueData as String: credentialsData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            logError("Keychain S3 credentials save failed with status: \(status)", category: .keychain)
            throw AppError.keychainSaveFailed
        }

        logDebug("S3 credentials saved for connection: \(connectionId)", category: .keychain)
    }

    func getS3Credentials(for connectionId: UUID) -> S3Credentials? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: s3Service,
            kSecAttrAccount as String: connectionId.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(S3Credentials.self, from: data) else {
            return nil
        }

        return credentials
    }

    func deleteS3Credentials(for connectionId: UUID) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: s3Service,
            kSecAttrAccount as String: connectionId.uuidString
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            logError("Keychain S3 credentials delete failed with status: \(status)", category: .keychain)
            throw AppError.keychainDeleteFailed
        }

        logDebug("S3 credentials deleted for connection: \(connectionId)", category: .keychain)
    }

    func updateS3Credentials(_ credentials: S3Credentials, for connectionId: UUID) throws {
        guard let credentialsData = try? JSONEncoder().encode(credentials) else {
            throw AppError.keychainSaveFailed
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: s3Service,
            kSecAttrAccount as String: connectionId.uuidString
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: credentialsData
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist, create it
            try saveS3Credentials(credentials, for: connectionId)
            return
        }

        if status != errSecSuccess {
            logError("Keychain S3 credentials update failed with status: \(status)", category: .keychain)
            throw AppError.keychainSaveFailed
        }

        logDebug("S3 credentials updated for connection: \(connectionId)", category: .keychain)
    }

    func hasS3Credentials(for connectionId: UUID) -> Bool {
        getS3Credentials(for: connectionId) != nil
    }
}
