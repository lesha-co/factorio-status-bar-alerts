//
//  factorio_statusbarApp.swift
//  factorio-statusbar
//
//  Created by lesha on 16. 4. 2026..
//

import AppKit
import SwiftUI

@main
struct factorio_statusbarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(vm: appDelegate.viewModel, grantAccess: appDelegate.grantAccess)
                .frame(width: 400, height: 200)
        }
        .windowResizability(.contentSize)
        .commands {
            RevokeAccessCommands(
                viewModel: appDelegate.viewModel, revokeAccess: appDelegate.revokeAccess)
        }
    }
}

struct RevokeAccessCommands: Commands {
    @ObservedObject var viewModel: ViewModel
    let revokeAccess: () -> Void

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Revoke Folder Access") {
                revokeAccess()
            }
            .disabled(!viewModel.hasAccess)
        }
    }
}
