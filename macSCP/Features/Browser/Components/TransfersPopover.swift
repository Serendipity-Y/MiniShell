//
//  TransfersPopover.swift
//  macSCP
//
//  Safari-style popover showing file transfer progress
//

import SwiftUI

struct TransfersPopover: View {
    @Bindable var viewModel: FileBrowserViewModel

    private var needsScrolling: Bool {
        viewModel.allTransfers.count > 5
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if viewModel.allTransfers.isEmpty {
                emptyState
            } else if needsScrolling {
                scrollableTransfersList
            } else {
                staticTransfersList
            }
        }
        .frame(width: 340)
    }

    private var header: some View {
        HStack {
            Text("传输")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if viewModel.hasActiveTransfers {
                Button("全部取消") {
                    viewModel.cancelAllTransfers()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.red)
            }

            if !viewModel.recentTransfers.isEmpty {
                Button("清除") {
                    viewModel.clearCompletedTransfers()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)

            Text("暂无传输任务")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // When few items, use a plain VStack so it sizes to content exactly
    private var staticTransfersList: some View {
        VStack(spacing: 0) {
            transferItems
        }
    }

    // When many items, use ScrollView with a fixed max height
    private var scrollableTransfersList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                transferItems
            }
        }
        .frame(maxHeight: 380)
    }

    @ViewBuilder
    private var transferItems: some View {
        ForEach(viewModel.allTransfers) { transfer in
            TransferItemView(
                transfer: transfer,
                onCancel: {
                    viewModel.cancelTransfer(transfer)
                },
                onRemove: {
                    viewModel.removeTransfer(transfer)
                }
            )

            if transfer.id != viewModel.allTransfers.last?.id {
                Divider()
                    .padding(.leading, 54) // Aligns with filename: 16 padding + 10 spacing + 28 icon
            }
        }
    }
}

// MARK: - Transfer Item View
struct TransferItemView: View {
    let transfer: TransferProgress
    let onCancel: () -> Void
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            statusIcon
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            // File info and progress
            VStack(alignment: .leading, spacing: 4) {
                Text(transfer.fileName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if transfer.isInProgress {
                    ProgressView(value: transfer.fractionCompleted)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)

                    HStack {
                        Text(transfer.progressText)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(transfer.percentCompleted)%")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                } else if transfer.isComplete {
                    Text(transfer.totalSizeText)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else if transfer.status == .failed {
                    Text(transfer.error ?? "传输失败")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if transfer.status == .cancelled {
                    Text("已取消")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }

            // Trailing action — always rendered to prevent layout shifts on hover
            Button(action: transfer.isInProgress ? onCancel : onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: transfer.isInProgress ? 16 : 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(transfer.isInProgress || isHovering ? 1 : 0)
            .help(transfer.isInProgress
                ? (transfer.transferType == .download ? "取消下载" : "取消上传")
                : "从列表中移除")
            .frame(width: 20, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(isHovering ? Color.primary.opacity(0.04) : .clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let action = transfer.transferType == .download ? "正在下载" : "正在上传"
        switch transfer.status {
        case .inProgress:
            return "\(transfer.fileName)，\(action)，已完成 \(transfer.percentCompleted)%"
        case .completed:
            return "\(transfer.fileName)，已完成，\(transfer.totalSizeText)"
        case .failed:
            return "\(transfer.fileName)，失败，\(transfer.error ?? "传输失败")"
        case .cancelled:
            return "\(transfer.fileName)，已取消"
        case .pending:
            return "\(transfer.fileName)，等待中"
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusBackgroundColor)

            if transfer.isInProgress {
                Image(systemName: transfer.transferType == .download ? "arrow.down" : "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            } else if transfer.isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            } else if transfer.status == .failed {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            } else if transfer.status == .cancelled {
                Image(systemName: "stop.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var statusBackgroundColor: Color {
        switch transfer.status {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .pending:
            return .orange
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Toolbar Transfers Button
struct TransfersToolbarButton: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        Button {
            viewModel.isShowingTransfersPopover.toggle()
        } label: {
            Label("传输", systemImage: viewModel.hasActiveTransfers ? "arrow.up.circle.fill" : "arrow.up.arrow.down.circle")
                .symbolEffect(.pulse, options: .repeating, isActive: viewModel.hasActiveTransfers)
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.activeTransferCount > 0 {
                Text("\(viewModel.activeTransferCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.blue))
                    .offset(x: 4, y: -4)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .popover(isPresented: $viewModel.isShowingTransfersPopover, arrowEdge: .bottom) {
            TransfersPopover(viewModel: viewModel)
        }
        .help("传输")
        .accessibilityLabel(viewModel.activeTransferCount > 0
            ? "传输，\(viewModel.activeTransferCount) 个进行中"
            : "传输")
    }
}

// MARK: - Preview
#Preview {
    TransfersPopover(
        viewModel: DependencyContainer.shared.makeFileBrowserViewModel(
            connection: Connection(name: "Test", host: "localhost", username: "user"),
            sftpSession: SFTPSession(),
            password: "test"
        )
    )
}
