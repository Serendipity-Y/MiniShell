//
//  ConnectionType.swift
//  macSCP
//
//  Connection type for distinguishing SFTP vs S3 connections
//

import Foundation

enum ConnectionType: String, Codable, Sendable, CaseIterable {
    case sftp
    case s3

    /// S3 remains in the stored model during the bootstrap phase, but MiniShell
    /// deliberately exposes only SSH/SFTP connections in its interface.
    static let selectableCases: [ConnectionType] = [.sftp]

    var displayName: String {
        switch self {
        case .sftp:
            return "SSH / SFTP"
        case .s3:
            return "S3"
        }
    }

    var iconName: String {
        switch self {
        case .sftp:
            return "server.rack"
        case .s3:
            return "externaldrive.connected.to.line.below"
        }
    }

    var description: String {
        switch self {
        case .sftp:
            return "Secure File Transfer Protocol"
        case .s3:
            return "Amazon S3 / S3-Compatible Storage"
        }
    }
}
