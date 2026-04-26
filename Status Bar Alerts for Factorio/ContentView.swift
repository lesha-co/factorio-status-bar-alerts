import SwiftUI

struct ModWarning: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("The **macos-status-bar-alerts** mod is not installed.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("Install the mod in Factorio's mod portal, then relaunch this app.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            HStack {
                Button("Open Factorio mod portal") {
                    if let url = URL(string: "https://mods.factorio.com/mod/" + modName) {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("Install mod directly") {

                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FolderAccessWarning: View {
    var onRequest: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {

            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("Folder access is required to monitor Factorio alerts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Grant Folder Access") {
                onRequest?()
            }
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MainView: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        Text(vm.isFactorioRunning ? "Factorio is running" : "Factorio is not running")
            .font(.headline)
            .padding()
        Text(vm.hasAccess ? "Had access" : "No access")
            .font(.headline)
            .padding()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
            ForEach(FactorioAlert.allCases, id: \.self) { alert in
                AlertIconView(
                    alert: alert,
                    count: vm.alerts[alert] ?? 0
                )
            }
        }
        .padding()
    }
}

struct ContentView: View {
    @ObservedObject var vm: ViewModel
    var grantAccess: (() -> Void)?

    var body: some View {
        if vm.hasAccess && vm.isModInstalled {
            MainView(vm: vm)
        } else if vm.hasAccess && !vm.isModInstalled {
            ModWarning()
        } else {
            FolderAccessWarning {
                grantAccess?()
            }
        }
    }
}

#Preview {
    ContentView(
        vm: {
            let vm = ViewModel()
            vm.alerts = [
                .entity_destroyed: 12,
                .no_storage: 5,
            ]
            vm.hasAccess = false
            return vm
        }(),
        grantAccess: nil
    )
}

#Preview {
    ContentView(
        vm: {
            let vm = ViewModel()
            vm.alerts = [
                .entity_destroyed: 12,
                .no_storage: 5,
            ]
            vm.hasAccess = true
            vm.isModInstalled = true
            return vm
        }(),
        grantAccess: nil
    )
}
#Preview {
    ModWarning()
}
