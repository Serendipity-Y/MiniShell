//
//  FileTypeService.swift
//  macSCP
//
//  Service for file type detection and categorization
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum FileTypeService {
    /// Returns the SF Symbol name for a file
    static func iconName(for file: RemoteFile) -> String {
        if file.isDirectory {
            return "folder.fill"
        }

        return file.fileType.iconName
    }

    /// Returns the icon color for a file type
    static func iconColor(for file: RemoteFile) -> Color {
        if file.isDirectory {
            return .blue
        }

        switch file.fileType {
        case .code, .configuration:
            return .orange
        case .image:
            return .purple
        case .video:
            return .pink
        case .audio:
            return .green
        case .archive:
            return .brown
        case .document, .text:
            return .blue
        case .spreadsheet:
            return .green
        case .presentation:
            return .orange
        case .pdf:
            return .red
        case .executable:
            return .gray
        default:
            return .secondary
        }
    }

    /// Returns whether a file can be previewed/edited in the app
    static func isPreviewable(_ file: RemoteFile) -> Bool {
        guard file.isFile else { return false }
        guard file.size <= FileOperationConstants.maxFilePreviewSize else { return false }

        return file.fileType.isEditable
    }

    /// Returns the UTType for a file extension
    static func utType(for extension: String) -> UTType? {
        UTType(filenameExtension: `extension`)
    }

    /// Returns the MIME type for a file
    static func mimeType(for file: RemoteFile) -> String {
        guard let utType = utType(for: file.fileExtension) else {
            return "application/octet-stream"
        }
        return utType.preferredMIMEType ?? "application/octet-stream"
    }

    /// Returns a human-readable description of the file type (Finder style)
    static func typeDescription(for file: RemoteFile) -> String {
        if file.isDirectory {
            return "文件夹"
        }

        if file.isSymlink {
            return "别名"
        }

        // Check for specific extensions first
        switch file.fileExtension.lowercased() {
        case "swift":
            return "Swift 源代码"
        case "js":
            return "JavaScript 文件"
        case "ts":
            return "TypeScript 文件"
        case "py":
            return "Python 脚本"
        case "rb":
            return "Ruby 脚本"
        case "go":
            return "Go 源代码"
        case "rs":
            return "Rust 源代码"
        case "java":
            return "Java 源代码"
        case "c":
            return "C 源代码"
        case "cpp", "cc":
            return "C++ 源代码"
        case "h":
            return "C 头文件"
        case "hpp":
            return "C++ 头文件"
        case "m":
            return "Objective-C 源代码"
        case "html", "htm":
            return "HTML 文档"
        case "css":
            return "CSS 样式表"
        case "json":
            return "JSON"
        case "xml":
            return "XML 文档"
        case "yaml", "yml":
            return "YAML 文档"
        case "md", "markdown":
            return "Markdown 文档"
        case "txt":
            return "纯文本"
        case "pdf":
            return "PDF 文档"
        case "png":
            return "PNG 图像"
        case "jpg", "jpeg":
            return "JPEG 图像"
        case "gif":
            return "GIF 图像"
        case "svg":
            return "SVG 图像"
        case "mp4":
            return "MPEG-4 视频"
        case "mov":
            return "QuickTime 视频"
        case "mp3":
            return "MP3 音频"
        case "wav":
            return "WAV 音频"
        case "zip":
            return "ZIP 压缩包"
        case "tar":
            return "TAR 压缩包"
        case "gz", "gzip":
            return "Gzip 压缩包"
        case "dmg":
            return "磁盘映像"
        case "app":
            return "应用程序"
        case "xcodeproj":
            return "Xcode 项目"
        case "xcworkspace":
            return "Xcode 工作区"
        default:
            break
        }

        // Fallback to general type
        switch file.fileType {
        case .directory:
            return "文件夹"
        case .text:
            return "纯文本"
        case .code:
            return "源代码"
        case .image:
            return "图像"
        case .video:
            return "视频"
        case .audio:
            return "音频"
        case .archive:
            return "压缩包"
        case .document:
            return "文档"
        case .spreadsheet:
            return "电子表格"
        case .presentation:
            return "演示文稿"
        case .pdf:
            return "PDF 文档"
        case .executable:
            return "Unix 可执行文件"
        case .configuration:
            return "配置文件"
        case .unknown:
            if file.fileExtension.isEmpty {
                return "文档"
            }
            return "文档"
        }
    }

    /// Groups files by their type
    static func groupByType(_ files: [RemoteFile]) -> [FileType: [RemoteFile]] {
        Dictionary(grouping: files, by: { $0.fileType })
    }

    /// Returns files filtered by type
    static func filter(_ files: [RemoteFile], byType type: FileType) -> [RemoteFile] {
        files.filter { $0.fileType == type }
    }
}

// MARK: - File Size Formatting
extension FileTypeService {
    /// Formats a byte count as a human-readable string
    static func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Formats permissions as a human-readable string
    static func formatPermissions(_ permissions: String) -> String {
        guard permissions.count == 10 else { return permissions }

        let type: String
        switch permissions.first {
        case "d": type = "目录"
        case "l": type = "符号链接"
        case "-": type = "文件"
        case "b": type = "块设备"
        case "c": type = "字符设备"
        case "p": type = "命名管道"
        case "s": type = "套接字"
        default: type = "未知"
        }

        let permString = String(permissions.dropFirst())
        let owner = formatPermissionGroup(String(permString.prefix(3)))
        let group = formatPermissionGroup(String(permString.dropFirst(3).prefix(3)))
        let other = formatPermissionGroup(String(permString.suffix(3)))

        return "\(type) - 所有者：\(owner)，用户组：\(group)，其他：\(other)"
    }

    private static func formatPermissionGroup(_ perms: String) -> String {
        var result: [String] = []
        if perms.contains("r") { result.append("读取") }
        if perms.contains("w") { result.append("写入") }
        if perms.contains("x") { result.append("执行") }
        return result.isEmpty ? "无" : result.joined(separator: "、")
    }
}
