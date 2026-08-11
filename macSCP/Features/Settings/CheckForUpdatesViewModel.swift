//
//  CheckForUpdatesViewModel.swift
//  macSCP
//

import Combine
import Foundation
import Sparkle

@MainActor
final class CheckForUpdatesViewModel: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    @Published var canCheckForUpdates = false

    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updater.checkForUpdates()
        logInfo("已触发手动检查更新", category: .app)
    }
}
