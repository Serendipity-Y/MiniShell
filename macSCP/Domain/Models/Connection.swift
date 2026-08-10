//
//  Connection.swift
//  macSCP
//
//  Domain model for SSH connections
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    static let connection = UTType(exportedAs: "com.minishell.connection")
}

struct Connection: Identifiable, Hashable, Sendable, Codable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .connection)
    }
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var privateKeyPath: String?
    var savePassword: Bool
    var description: String?
    var tags: [String]
    var iconName: String
    var folderId: UUID?
    var createdAt: Date
    var updatedAt: Date

    // S3-specific fields
    var connectionType: ConnectionType
    var s3Region: String?
    var s3Bucket: String?
    var s3Endpoint: String?

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .password,
        privateKeyPath: String? = nil,
        savePassword: Bool = false,
        description: String? = nil,
        tags: [String] = [],
        iconName: String = "server.rack",
        folderId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        connectionType: ConnectionType = .sftp,
        s3Region: String? = nil,
        s3Bucket: String? = nil,
        s3Endpoint: String? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.privateKeyPath = privateKeyPath
        self.savePassword = savePassword
        self.description = description
        self.tags = tags
        self.iconName = iconName
        self.folderId = folderId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.connectionType = connectionType
        self.s3Region = s3Region
        self.s3Bucket = s3Bucket
        self.s3Endpoint = s3Endpoint
    }

    // MARK: - Computed Properties
    var displayHost: String {
        switch connectionType {
        case .sftp:
            if port == 22 {
                return host
            }
            return "\(host):\(port)"
        case .s3:
            if let endpoint = s3Endpoint, !endpoint.isEmpty {
                return endpoint
            }
            return s3Bucket ?? "S3"
        }
    }

    var connectionString: String {
        switch connectionType {
        case .sftp:
            return "\(username)@\(displayHost)"
        case .s3:
            if let bucket = s3Bucket {
                return "s3://\(bucket)"
            }
            return "S3"
        }
    }

    var hasDescription: Bool {
        description?.isBlank == false
    }

    var hasTags: Bool {
        !tags.isEmpty
    }

    // MARK: - Methods
    func withUpdatedTimestamp() -> Connection {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Validation
extension Connection {
    var isValid: Bool {
        switch connectionType {
        case .sftp:
            return isSFTPValid
        case .s3:
            return isS3Valid
        }
    }

    private var isSFTPValid: Bool {
        !name.isBlank &&
        !host.isBlank &&
        !username.isBlank &&
        port > 0 && port <= 65535 &&
        (authMethod == .password || privateKeyPath != nil)
    }

    private var isS3Valid: Bool {
        !name.isBlank &&
        !username.isBlank &&  // Access Key ID
        !(s3Bucket?.isBlank ?? true)
    }

    var validationErrors: [String] {
        switch connectionType {
        case .sftp:
            return sftpValidationErrors
        case .s3:
            return s3ValidationErrors
        }
    }

    private var sftpValidationErrors: [String] {
        var errors: [String] = []
        if name.isBlank {
            errors.append("Name is required")
        }
        if host.isBlank {
            errors.append("Host is required")
        }
        if username.isBlank {
            errors.append("Username is required")
        }
        if port <= 0 || port > 65535 {
            errors.append("Port must be between 1 and 65535")
        }
        if authMethod == .privateKey && (privateKeyPath?.isBlank ?? true) {
            errors.append("Private key path is required for key authentication")
        }
        return errors
    }

    private var s3ValidationErrors: [String] {
        var errors: [String] = []
        if name.isBlank {
            errors.append("Name is required")
        }
        if username.isBlank {
            errors.append("Access Key ID is required")
        }
        if s3Bucket?.isBlank ?? true {
            errors.append("Bucket name is required")
        }
        return errors
    }

    var isS3Connection: Bool {
        connectionType == .s3
    }

    var isSFTPConnection: Bool {
        connectionType == .sftp
    }
}
