//
//  ErrorContent.swift
//  Status Bar Alerts for Factorio
//
//  Created by lesha on 30. 4. 2026..
//
import SwiftUI

struct ErrorContent: View {
    var folderAccess: Bool
    var modInstalled: Bool

    var onRequestFolderAccess: (() -> Void)?
    var onRequestModInstallation: (() -> Void)?
    var onRequestOpenFactorioModWebsite: (() -> Void)?

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
                        Text("You can revoke it from application menu")
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

            HStack {
                Image(systemName: "gearshape")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                    .frame(maxHeight: 40)
                Text("Factorio is not running")
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        // .frame(maxWidth: 200)
        .padding()

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
