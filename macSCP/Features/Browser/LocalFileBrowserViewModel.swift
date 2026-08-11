//
//  LocalFileBrowserViewModel.swift
//  macSCP
//
//  State for the local half of the SFTP workspace.
//

import Foundation

struct LocalFileItem: Identifiable, Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date?

    var id: URL { url }

    var displaySize: String {
        isDirectory ? "--" : ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var typeDescription: String {
        isDirectory ? "文件夹" : (url.pathExtension.isEmpty ? "文件" : url.pathExtension.uppercased() + " 文件")
    }
}

@MainActor
@Observable
final class LocalFileBrowserViewModel {
    private(set) var currentURL: URL
    private(set) var items: [LocalFileItem] = []
    var selectedURLs: Set<URL> = []
    var error: AppError?

    private var backHistory: [URL] = []
    private var forwardHistory: [URL] = []

    init(startURL: URL? = nil) {
        currentURL = startURL ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        loadFiles()
    }

    var canGoBack: Bool { !backHistory.isEmpty }
    var canGoForward: Bool { !forwardHistory.isEmpty }
    var canGoUp: Bool { currentURL.path != "/" }

    var pathDisplayName: String {
        currentURL.path.isEmpty ? "/" : currentURL.path
    }

    func loadFiles() {
        do {
            let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
            let urls = try FileManager.default.contentsOfDirectory(
                at: currentURL,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsPackageDescendants]
            )

            items = try urls.map { url in
                let values = try url.resourceValues(forKeys: keys)
                return LocalFileItem(
                    url: url,
                    name: url.lastPathComponent,
                    isDirectory: values.isDirectory ?? false,
                    size: Int64(values.fileSize ?? 0),
                    modificationDate: values.contentModificationDate
                )
            }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            selectedURLs.removeAll()
        } catch {
            self.error = AppError.from(error)
            items = []
        }
    }

    func navigateTo(_ url: URL) {
        guard url.hasDirectoryPath else { return }
        backHistory.append(currentURL)
        forwardHistory.removeAll()
        currentURL = url.standardizedFileURL
        loadFiles()
    }

    func goBack() {
        guard let previous = backHistory.popLast() else { return }
        forwardHistory.append(currentURL)
        currentURL = previous
        loadFiles()
    }

    func goForward() {
        guard let next = forwardHistory.popLast() else { return }
        backHistory.append(currentURL)
        currentURL = next
        loadFiles()
    }

    func goUp() {
        guard canGoUp else { return }
        navigateTo(currentURL.deletingLastPathComponent())
    }

    func open(_ item: LocalFileItem) {
        guard item.isDirectory else { return }
        navigateTo(item.url)
    }
}
