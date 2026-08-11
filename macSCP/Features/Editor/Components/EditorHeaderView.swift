//
//  EditorHeaderView.swift
//  macSCP
//
//  Header view for the file editor
//

import SwiftUI

struct EditorHeaderView: View {
    @Bindable var viewModel: FileEditorViewModel

    var body: some View {
        HStack {
            // File info
            HStack(spacing: UIConstants.smallSpacing) {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)

                Text(viewModel.fileName)
                    .font(.headline)

                if viewModel.hasChanges {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                        .help("有未保存的更改")
                }
            }

            Spacer()

            // Actions
            HStack(spacing: UIConstants.smallSpacing) {
                Button {
                    Task {
                        await viewModel.reload()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("从服务器重新加载")

                Button {
                    viewModel.revertChanges()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.hasChanges)
                .help("还原更改")

                Button {
                    Task {
                        await viewModel.save()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.hasChanges)
                .help("保存")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Preview
#Preview {
    EditorHeaderView(viewModel: FileEditorViewModel(
        filePath: "/test.txt",
        fileName: "test.txt",
        initialContent: "Hello",
        fileRepository: FileRepository(sftpSession: SFTPSession())
    ))
}
