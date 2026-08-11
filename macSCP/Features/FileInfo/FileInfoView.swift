//
//  FileInfoView.swift
//  macSCP
//
//  View displaying file information
//

import SwiftUI

struct FileInfoView: View {
    let viewModel: FileInfoViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon
            headerSection

            Divider()

            // Info sections
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.spacing) {
                    generalSection
                    locationSection
                    permissionsSection

                    if viewModel.isDirectory {
                        directorySection
                    } else {
                        fileSection
                    }
                }
                .padding()
            }
        }
        .frame(width: WindowSize.fileInfo.width, height: WindowSize.fileInfo.height)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: UIConstants.smallSpacing) {
            Image(systemName: viewModel.iconName)
                .font(.system(size: 48))
                .foregroundStyle(viewModel.iconColor)

            Text(viewModel.fileName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(viewModel.fileType)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
    }

    private var generalSection: some View {
        InfoSection(title: "通用") {
            InfoRow(label: "种类", value: viewModel.fileType)
            InfoRow(label: "大小", value: viewModel.fileSize)

            if !viewModel.isDirectory {
                InfoRow(label: "扩展名", value: viewModel.fileExtension)
            }

            InfoRow(label: "修改时间", value: viewModel.modificationDate)
        }
    }

    private var locationSection: some View {
        InfoSection(title: "位置") {
            InfoRow(label: "路径", value: viewModel.filePath)
            InfoRow(label: "上级目录", value: viewModel.parentDirectory)
            InfoRow(label: "服务器", value: viewModel.connectionName)
        }
    }

    private var permissionsSection: some View {
        InfoSection(title: "权限") {
            InfoRow(label: "模式", value: viewModel.permissions)

            VStack(alignment: .leading, spacing: 4) {
                Text("详情")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.permissionsDescription)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var directorySection: some View {
        InfoSection(title: "目录信息") {
            InfoRow(label: "类型", value: "文件夹")
        }
    }

    private var fileSection: some View {
        InfoSection(title: "文件信息") {
            InfoRow(label: "隐藏", value: viewModel.isHidden ? "是" : "否")
            InfoRow(label: "可执行", value: viewModel.isExecutable ? "是" : "否")
            InfoRow(label: "可编辑", value: viewModel.isEditable ? "是" : "否")

            if viewModel.isSymlink {
                InfoRow(label: "符号链接", value: "是")
            }
        }
    }
}

// MARK: - Info Section
private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: UIConstants.smallCornerRadius))
        }
    }
}

// MARK: - Info Row
private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.callout)
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
        }
    }
}

// MARK: - Preview
#Preview {
    FileInfoView(viewModel: FileInfoViewModel(
        file: RemoteFile(
            name: "example.swift",
            path: "/home/user/projects/example.swift",
            isDirectory: false,
            size: 4096,
            permissions: "-rw-r--r--",
            modificationDate: Date()
        ),
        connectionName: "Production Server"
    ))
}
