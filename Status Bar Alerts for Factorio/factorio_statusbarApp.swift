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
            ContentView(
                vm: appDelegate.viewModel,
                grantAccess: appDelegate.grantAccess,
                onModInstall: appDelegate.installMod
            )
            .frame(width: 400, height: 200)
        }
        .windowResizability(.contentSize)
        .commands {
            MenuCommands(
                viewModel: appDelegate.viewModel,
                revokeAccess: appDelegate.revokeAccess,
                installMod: appDelegate.installMod,
                openFactorioFolder: appDelegate.openFactorioFolder,
                deleteMod: appDelegate.deleteMod
            )
        }

    }
}

struct MenuCommands: Commands {
    @ObservedObject var viewModel: ViewModel
    let revokeAccess: () -> Void
    let installMod: () -> Void
    let openFactorioFolder: () -> Void
    let deleteMod: () -> Void

    var body: some Commands {
        CommandGroup(after: .appSettings) {
            Button("Revoke Folder Access") {
                revokeAccess()
            }
            .disabled(!viewModel.hasAccess)

            Button("Install Mod directly") {
                installMod()
            }
            
            Button("Delete Mod") {
                deleteMod()
            }
            
            Button("Open Factorio application data folder") {
                openFactorioFolder()
            }

        }
    }
}
