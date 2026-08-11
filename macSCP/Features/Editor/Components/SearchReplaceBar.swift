//
//  SearchReplaceBar.swift
//  macSCP
//
//  Search and replace bar for the file editor
//

import SwiftUI

struct SearchReplaceBar: View {
    @Bindable var viewModel: FileEditorViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: UIConstants.smallSpacing) {
            // Search row
            HStack(spacing: UIConstants.smallSpacing) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("搜索", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit {
                        viewModel.search()
                    }
                    .onChange(of: viewModel.searchText) {
                        viewModel.search()
                    }

                // Options
                Toggle(isOn: $viewModel.isCaseSensitive) {
                    Text("Aa")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .help("区分大小写")
                .onChange(of: viewModel.isCaseSensitive) {
                    viewModel.search()
                }

                Toggle(isOn: $viewModel.isWholeWord) {
                    Image(systemName: "textformat")
                }
                .toggleStyle(.button)
                .help("全词匹配")
                .onChange(of: viewModel.isWholeWord) {
                    viewModel.search()
                }

                // Navigation
                Button {
                    viewModel.findPrevious()
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.searchResults.isEmpty)

                Button {
                    viewModel.findNext()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.searchResults.isEmpty)

                // Status
                Text(viewModel.searchStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 60)

                // Close
                Button {
                    viewModel.toggleSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Replace row
            HStack(spacing: UIConstants.smallSpacing) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(.secondary)

                TextField("替换为", text: $viewModel.replaceText)
                    .textFieldStyle(.plain)

                Button("替换") {
                    viewModel.replaceCurrent()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.searchResults.isEmpty)

                Button("全部替换") {
                    viewModel.replaceAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.searchResults.isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
        .onAppear {
            isSearchFocused = true
        }
    }
}

// MARK: - Preview
#Preview {
    SearchReplaceBar(viewModel: FileEditorViewModel(
        filePath: "/test.txt",
        fileName: "test.txt",
        initialContent: "Hello, World! Hello again!",
        fileRepository: FileRepository(sftpSession: SFTPSession())
    ))
}
