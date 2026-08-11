//
//  AppError.swift
//  macSCP
//
//  Unified error types for the application
//

import Foundation

enum AppError: LocalizedError, Sendable {
    // Connection errors
    case connectionFailed(String)
    case connectionTimeout
    case connectionLost
    case authenticationFailed
    case hostUnreachable

    // SFTP errors
    case sftpOperationFailed(String)
    case permissionDenied
    case fileNotFound
    case fileAlreadyExists
    case directoryNotEmpty
    case invalidPath

    // Data errors
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case entityNotFound

    // Keychain errors
    case keychainSaveFailed
    case keychainReadFailed
    case keychainDeleteFailed

    // File operation errors
    case downloadFailed(String)
    case uploadFailed(String)
    case fileReadFailed
    case fileWriteFailed

    // Terminal errors
    case terminalConnectionFailed(String)
    case terminalConnectionLost
    case terminalPTYFailed

    // Biometric errors
    case biometricNotAvailable
    case biometricAuthFailed(String)

    // General errors
    case unknown(String)
    case notConnected

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "连接失败：\(message)"
        case .connectionTimeout:
            return "连接超时"
        case .connectionLost:
            return "连接已断开"
        case .authenticationFailed:
            return "身份验证失败，请检查凭据。"
        case .hostUnreachable:
            return "无法访问主机，请检查主机地址和网络连接。"

        case .sftpOperationFailed(let message):
            return "SFTP 操作失败：\(message)"
        case .permissionDenied:
            return "权限不足"
        case .fileNotFound:
            return "未找到文件或目录"
        case .fileAlreadyExists:
            return "同名文件或目录已存在"
        case .directoryNotEmpty:
            return "目录不为空"
        case .invalidPath:
            return "路径无效"

        case .saveFailed(let message):
            return "保存失败：\(message)"
        case .fetchFailed(let message):
            return "读取失败：\(message)"
        case .deleteFailed(let message):
            return "删除失败：\(message)"
        case .entityNotFound:
            return "未找到数据"

        case .keychainSaveFailed:
            return "无法将密码保存到钥匙串"
        case .keychainReadFailed:
            return "无法从钥匙串读取密码"
        case .keychainDeleteFailed:
            return "无法从钥匙串删除密码"

        case .downloadFailed(let message):
            return "下载失败：\(message)"
        case .uploadFailed(let message):
            return "上传失败：\(message)"
        case .fileReadFailed:
            return "读取文件失败"
        case .fileWriteFailed:
            return "写入文件失败"

        case .terminalConnectionFailed(let message):
            return "终端连接失败：\(message)"
        case .terminalConnectionLost:
            return "终端连接已丢失"
        case .terminalPTYFailed:
            return "无法分配伪终端"

        case .biometricNotAvailable:
            return "此 Mac 不支持触控 ID"
        case .biometricAuthFailed(let message):
            return "身份验证失败：\(message)"

        case .unknown(let message):
            return message
        case .notConnected:
            return "尚未连接到服务器"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed, .connectionTimeout, .hostUnreachable:
            return "请检查网络连接和服务器地址。"
        case .authenticationFailed:
            return "请确认用户名和密码。"
        case .permissionDenied:
            return "你没有执行此操作的权限。"
        case .notConnected:
            return "请先连接服务器。"
        case .terminalConnectionFailed, .terminalConnectionLost:
            return "请检查网络连接后重新连接。"
        case .terminalPTYFailed:
            return "服务器可能不支持交互式终端，请重试。"
        case .biometricNotAvailable:
            return "请使用支持触控 ID 的 Mac，或配对 Apple Watch 后启用生物认证。"
        case .biometricAuthFailed:
            return "请重试或使用系统密码。"
        default:
            return nil
        }
    }
}

// MARK: - Error Conversion
extension AppError {
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
