//
//  ErrorContent.swift
//  Status Bar Alerts for Factorio
//
//  Created by lesha on 30. 4. 2026..
//
import SwiftUI

func getURLsForFactorio() -> [URL] {
    let bundleIdentifier = "com.factorio"
    guard let urls = LSCopyApplicationURLsForBundleIdentifier(bundleIdentifier as CFString, nil)
    else {
        return []
    }
    let urls2 = urls.takeRetainedValue() as? [URL] ?? []

    return urls2

}

struct ErrorContent: View {
    var folderAccess: Bool
    var modInstalled: Bool

    var onRequestFolderAccess: (() -> Void)?
    var onRequestModInstallation: (() -> Void)?
    var onRequestOpenFactorioModWebsite: (() -> Void)?

    @AppStorage("selectedApp") var selectedApp: URL?
    var factorioURLs: [URL] { getURLsForFactorio() }

    func startFactorio() {
        if let url = selectedApp {
            NSWorkspace.shared.openApplication(
                at: url,
                configuration: NSWorkspace.OpenConfiguration()
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if folderAccess {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                        .frame(maxHeight: 40)
                    VStack(alignment: .leading, ) {
                        Text("Access has been granted")
                        Text("You can revoke access from application menu")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                        .frame(maxHeight: 40)
                    VStack(alignment: .leading, ) {
                        Text("No access to the folder")
                        Text("Folder access is required to monitor Factorio alerts.")
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Grant Folder Access") {
                    onRequestFolderAccess?()
                }
                .controlSize(.large)
                .disabled(folderAccess)

            }
            .frame(maxWidth: .infinity)

            HStack {
                if modInstalled {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                        .frame(maxHeight: 40)
                    VStack(alignment: .leading, ) {
                        Text("Mod is installed")

                    }
                } else {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                        .frame(maxHeight: 40)
                    VStack(alignment: .leading, ) {
                        Text("Mod is not installed")

                    }
                }
                Spacer()
                Button("Install mod") {
                    onRequestModInstallation?()
                }
                .controlSize(.large)
                .disabled(modInstalled || !folderAccess)
                Button("Open mod page on Factorio.com") {
                    onRequestModInstallation?()
                }
                .controlSize(.large)
                .disabled(modInstalled)
            }
            .frame(maxWidth: .infinity)
            .opacity(folderAccess ? 1.0 : 0.2)
            .disabled(!folderAccess)

            HStack {
                Image(systemName: "gearshape")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                    .frame(maxHeight: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Factorio is not running")
                    Picker("Application", selection: $selectedApp) {
                        ForEach(factorioURLs, id: \.path) { url in
                            Text(url.path).tag(url)
                        }
                    }
                    .labelsHidden()
                }.frame(width: 300)
                Spacer()

                Button(action: { startFactorio() }) {
                    HStack(alignment: .firstTextBaseline) {
                        // actually IEC 60417-5104 which is MOST fitting symbol
                        Image(systemName: "minus.diamond").rotationEffect(Angle(degrees: 90))
                        Text("Start Factorio")
                    }
                }
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .opacity((folderAccess && modInstalled) ? 1.0 : 0.2)
            .disabled(!folderAccess || !modInstalled)
        }
        .padding()
        .onAppear {
            if factorioURLs.isEmpty { return }
            if let selectedApp, factorioURLs.contains(where: { $0 == selectedApp }) {
                return
            }
            selectedApp = factorioURLs.first
        }
    }
}

#Preview("No access") {
    ErrorContent(
        folderAccess: false, modInstalled: false
    )
}

#Preview("With folder access") {
    ErrorContent(
        folderAccess: true, modInstalled: false
    )
}

#Preview("Mod is installed") {
    ErrorContent(
        folderAccess: true, modInstalled: true
    )
}
