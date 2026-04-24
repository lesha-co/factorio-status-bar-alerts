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
            RootView()
                .environmentObject(appDelegate.viewModel)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
        ContentView(vm: viewModel)
    }
}
