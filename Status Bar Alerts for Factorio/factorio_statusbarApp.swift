//
//  factorio_statusbarApp.swift
//  factorio-statusbar
//
//  Created by lesha on 16. 4. 2026..
//

import AppKit
import Sparkle
import SwiftUI

@main
struct factorio_statusbarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // private let updaterController = SPUStandardUpdaterController(
    //     startingUpdater: true,
    //     updaterDelegate: nil,
    //     userDriverDelegate: nil
    // )

    var body: some Scene {
        WindowGroup {
            ContentView(
                vm: appDelegate.viewModel,
                grantAccess: appDelegate.grantAccess,
                onModInstall: appDelegate.installMod,
                resetAcknowledgedAlerts: appDelegate.resetAcknowledgedAlerts
            )
            .frame(width: 550, height: 300)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Status Bar Alerts for Factorio") {
                    appDelegate.showAbout()
                }
            }
            // CommandGroup(after: .appInfo) {
            //     CheckForUpdatesView(updater: updaterController.updater)
            // }
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

            Button("Open Factorio application data folder") {
                openFactorioFolder()
            }

            Divider()

            Button("Install Mod directly") {
                installMod()
            }

            Button("Delete Mod") {
                deleteMod()
            }
        }
    }
}
