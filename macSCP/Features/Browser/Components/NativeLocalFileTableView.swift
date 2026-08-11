//
//  NativeLocalFileTableView.swift
//  macSCP
//
//  Native local file table with SFTP file-promise receiving support.
//

import AppKit
import SwiftUI

struct NativeLocalFileTableView: NSViewRepresentable {
    @Bindable var viewModel: LocalFileBrowserViewModel

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        let columns: [(String, String, CGFloat)] = [
            ("name", "名称", 220),
            ("size", "大小", 90),
            ("kind", "类型", 120),
            ("date", "修改时间", 145)
        ]
        for (identifier, title, width) in columns {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
            column.title = title
            column.width = width
            column.minWidth = identifier == "name" ? 140 : 70
            tableView.addTableColumn(column)
        }

        tableView.style = .inset
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.rowHeight = 28
        tableView.intercellSpacing = NSSize(width: 6, height: 2)
        tableView.target = context.coordinator
        tableView.doubleAction = #selector(Coordinator.handleDoubleClick(_:))
        tableView.setDraggingSourceOperationMask(.copy, forLocal: true)
        tableView.setDraggingSourceOperationMask(.copy, forLocal: false)
        tableView.registerForDraggedTypes([.fileURL, NSPasteboard.PasteboardType("com.apple.NSFilePromiseProvider")])
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.viewModel = viewModel
        guard let tableView = context.coordinator.tableView else { return }
        context.coordinator.isUpdating = true
        tableView.reloadData()
        let selectedRows = IndexSet(viewModel.items.enumerated().compactMap { viewModel.selectedURLs.contains($0.element.url) ? $0.offset : nil })
        tableView.selectRowIndexes(selectedRows, byExtendingSelection: false)
        context.coordinator.isUpdating = false
    }

    func makeCoordinator() -> Coordinator { Coordinator(viewModel: viewModel) }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var viewModel: LocalFileBrowserViewModel
        weak var tableView: NSTableView?
        var isUpdating = false

        init(viewModel: LocalFileBrowserViewModel) {
            self.viewModel = viewModel
        }

        func numberOfRows(in tableView: NSTableView) -> Int { viewModel.items.count }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row < viewModel.items.count else { return nil }
            let item = viewModel.items[row]
            let identifier = tableColumn?.identifier.rawValue ?? ""
            let cellID = NSUserInterfaceItemIdentifier("LocalCell_\(identifier)")
            let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTableCellView ?? makeCell(identifier: cellID, withIcon: identifier == "name")

            switch identifier {
            case "name":
                cell.textField?.stringValue = item.name
                cell.imageView?.image = NSWorkspace.shared.icon(forFile: item.url.path)
            case "size":
                cell.textField?.stringValue = item.displaySize
            case "kind":
                cell.textField?.stringValue = item.typeDescription
            case "date":
                cell.textField?.stringValue = item.modificationDate?.fileListDisplayString ?? "--"
            default:
                break
            }
            cell.textField?.textColor = identifier == "name" ? .labelColor : .secondaryLabelColor
            return cell
        }

        private func makeCell(identifier: NSUserInterfaceItemIdentifier, withIcon: Bool) -> NSTableCellView {
            let cell = NSTableCellView()
            cell.identifier = identifier
            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.lineBreakMode = .byTruncatingTail
            textField.font = .systemFont(ofSize: 13)
            cell.addSubview(textField)
            cell.textField = textField
            if withIcon {
                let imageView = NSImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.imageScaling = .scaleProportionallyUpOrDown
                cell.addSubview(imageView)
                cell.imageView = imageView
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                    imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 20),
                    imageView.heightAnchor.constraint(equalToConstant: 20),
                    textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            }
            return cell
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard !isUpdating, let tableView else { return }
            viewModel.selectedURLs = Set(tableView.selectedRowIndexes.compactMap { index in
                index < viewModel.items.count ? viewModel.items[index].url : nil
            })
        }

        @objc func handleDoubleClick(_ sender: NSTableView) {
            let row = sender.clickedRow
            guard row >= 0, row < viewModel.items.count else { return }
            viewModel.open(viewModel.items[row])
        }

        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
            guard row < viewModel.items.count else { return nil }
            return viewModel.items[row].url as NSURL
        }

        func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
            let pasteboard = info.draggingPasteboard
            if pasteboard.canReadObject(forClasses: [NSFilePromiseReceiver.self], options: nil) {
                tableView.setDropRow(-1, dropOperation: .on)
                return .copy
            }
            return []
        }

        func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
            guard let receivers = info.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] else {
                return false
            }
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: viewModel.currentURL, options: [:], operationQueue: .main) { [weak self] _, _ in
                    DispatchQueue.main.async { self?.viewModel.loadFiles() }
                }
            }
            return true
        }
    }
}
