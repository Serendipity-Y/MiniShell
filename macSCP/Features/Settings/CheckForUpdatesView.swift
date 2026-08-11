//
//  CheckForUpdatesView.swift
//  macSCP
//

import SwiftUI

struct CheckForUpdatesView: View {
    @ObservedObject var viewModel: CheckForUpdatesViewModel

    var body: some View {
        Button("检查更新…", action: viewModel.checkForUpdates)
            .disabled(!viewModel.canCheckForUpdates)
    }
}
