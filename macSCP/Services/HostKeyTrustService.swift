//
//  HostKeyTrustService.swift
//  MiniShell
//
//  Verifies SSH server host keys with explicit trust on first use.
//

import AppKit
import Citadel
import CryptoKit
import Foundation
import NIOCore
import NIOSSH

enum HostKeyValidationError: LocalizedError {
    case rejectedByUser
    case changed

    var errorDescription: String? {
        switch self {
        case .rejectedByUser:
            return "你已取消信任该服务器的主机密钥。"
        case .changed:
            return "服务器主机密钥已变化。为保护连接安全，MiniShell 已拒绝本次连接。"
        }
    }
}

/// 保存用户明确确认过的 SSH 主机公钥。
/// 密码仍仅由 `KeychainService` 保存；本服务不会读取或保存任何凭据。
final class HostKeyTrustService: @unchecked Sendable {
    static let shared = HostKeyTrustService()

    private enum Keys {
        static let trustedHostKeys = "trustedSSHHostKeys"
    }

    private let lock = NSLock()
    private let defaults: UserDefaults
    private var trustedKeys: [String: String]

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.trustedKeys = defaults.dictionary(forKey: Keys.trustedHostKeys) as? [String: String] ?? [:]
    }

    func validator(host: String, port: Int) -> SSHHostKeyValidator {
        SSHHostKeyValidator.custom(HostKeyValidator(service: self, host: host, port: port))
    }

    fileprivate func validate(hostKey: NIOSSHPublicKey, host: String, port: Int) throws {
        let identifier = Self.identifier(for: host, port: port)
        let openSSHKey = String(openSSHPublicKey: hostKey)

        lock.lock()
        let trustedKey = trustedKeys[identifier]
        lock.unlock()

        if let trustedKey {
            guard trustedKey == openSSHKey else {
                logWarning("SSH 主机密钥已变化，已拒绝连接", category: .network)
                throw HostKeyValidationError.changed
            }
            return
        }

        guard Self.confirmTrust(host: host, port: port, fingerprint: Self.fingerprint(for: openSSHKey)) else {
            throw HostKeyValidationError.rejectedByUser
        }

        lock.lock()
        trustedKeys[identifier] = openSSHKey
        defaults.set(trustedKeys, forKey: Keys.trustedHostKeys)
        lock.unlock()
    }

    private static func identifier(for host: String, port: Int) -> String {
        "\(host.lowercased()):\(port)"
    }

    private static func fingerprint(for openSSHKey: String) -> String {
        let components = openSSHKey.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        let keyData = components.count > 1 ? Data(base64Encoded: String(components[1])) : nil
        let digest = SHA256.hash(data: keyData ?? Data(openSSHKey.utf8))
        return "SHA256:" + Data(digest).base64EncodedString().replacingOccurrences(of: "=", with: "")
    }

    private static func confirmTrust(host: String, port: Int, fingerprint: String) -> Bool {
        let presentAlert = {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "验证服务器身份"
            alert.informativeText = "这是首次连接到 \(host):\(port)。请通过可信渠道核对主机密钥指纹；确认无误后再继续。\n\n\(fingerprint)"
            alert.addButton(withTitle: "信任并连接")
            alert.addButton(withTitle: "取消")
            return alert.runModal() == .alertFirstButtonReturn
        }

        if Thread.isMainThread {
            return presentAlert()
        }
        return DispatchQueue.main.sync(execute: presentAlert)
    }
}

private final class HostKeyValidator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
    private let service: HostKeyTrustService
    private let host: String
    private let port: Int

    init(service: HostKeyTrustService, host: String, port: Int) {
        self.service = service
        self.host = host
        self.port = port
    }

    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        do {
            try service.validate(hostKey: hostKey, host: host, port: port)
            validationCompletePromise.succeed(())
        } catch {
            validationCompletePromise.fail(error)
        }
    }
}
