//
//  EditorStatusBar.swift
//  macSCP
//
//  Status bar for the file editor
//

import SwiftUI

struct EditorStatusBar: View {
    @Bindable var viewModel: FileEditorViewModel

    var body: some View {
        HStack {
            // File path
            Text(viewModel.filePath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Statistics
            HStack(spacing: UIConstants.spacing) {
                StatItem(label: "行", value: "\(viewModel.lineCount)")
                StatItem(label: "词", value: "\(viewModel.wordCount)")
                StatItem(label: "字符", value: "\(viewModel.characterCount)")
            }

            // Save status
            if viewModel.state.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if viewModel.hasChanges {
                Text("已修改")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("已保存")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    EditorStatusBar(viewModel: FileEditorViewModel(
        filePath: "/home/user/documents/test.txt",
        fileName: "test.txt",
        initialContent: "Hello, World!",
        fileRepository: FileRepository(sftpSession: SFTPSession())
    ))
}
