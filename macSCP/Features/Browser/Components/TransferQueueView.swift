//
//  TransferQueueView.swift
//  macSCP
//
//  Persistent transfer queue for the dual-pane SFTP workspace.
//

import SwiftUI

struct TransferQueueView: View {
    @Bindable var viewModel: FileBrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("传输", systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                Text("日志")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.hasActiveTransfers {
                    Button("全部取消") { viewModel.cancelAllTransfers() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                }
                if !viewModel.recentTransfers.isEmpty {
                    Button("清除已完成") { viewModel.clearCompletedTransfers() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(.bar)

            Divider()

            if viewModel.allTransfers.isEmpty {
                ContentUnavailableView("暂无传输任务", systemImage: "arrow.up.arrow.down.circle")
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.allTransfers) {
                    TableColumn("名称") { transfer in Text(transfer.fileName).lineLimit(1) }
                    TableColumn("状态") { transfer in Text(statusText(transfer.status)) }
                    TableColumn("进度") { transfer in
                        if transfer.isInProgress {
                            ProgressView(value: transfer.fractionCompleted)
                                .frame(minWidth: 90)
                        } else {
                            Text(transfer.isComplete ? "已完成" : statusText(transfer.status))
                        }
                    }
                    TableColumn("大小") { transfer in Text(transfer.totalSizeText) }
                    TableColumn("本机路径") { transfer in Text(transfer.localURL?.path ?? "--").lineLimit(1) }
                    TableColumn("远端路径") { transfer in Text(transfer.remotePath).lineLimit(1) }
                }
                .font(.system(size: 11))
            }
        }
        .frame(minHeight: 145, idealHeight: 175, maxHeight: 230)
    }

    private func statusText(_ status: TransferStatus) -> String {
        switch status {
        case .pending: return "等待中"
        case .inProgress: return "传输中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        }
    }
}
