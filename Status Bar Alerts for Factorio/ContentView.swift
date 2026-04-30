import SwiftUI

struct MainView: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                ForEach(FactorioAlert.allCases, id: \.self) { alert in
                    AlertIconView(
                        alert: alert,
                        count: vm.alerts[alert] ?? 0
                    )
                }
            }
            Button {
                if let url = URL(string: "https://lesha.co/donate") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image(systemName: "dollarsign.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.accentColor)
                Text("Consider donating")
            }
            .padding()
        }.padding()
    }
}

struct ContentView: View {
    @ObservedObject var vm: ViewModel
    var grantAccess: (() -> Void)?
    var onModInstall: (() -> Void)?

    func openModWebsite() {
        if let url = URL(string: "https://mods.factorio.com/mod/" + modName) {
            NSWorkspace.shared.open(url)
        }
    }
    
    var body: some View {
        if vm.hasAccess && vm.isModInstalled && vm.isFactorioRunning {
            MainView(vm: vm)
        } else {
            ErrorContent(folderAccess: vm.hasAccess, modInstalled: vm.isModInstalled, onRequestFolderAccess: grantAccess, onRequestModInstallation: onModInstall, onRequestOpenFactorioModWebsite: openModWebsite)
        }
    }
}

#Preview("Main") {
    ContentView(
        vm: {
            let vm = ViewModel()
            vm.alerts = [
                .entity_destroyed: 12,
                .no_storage: 5,
            ]
            vm.hasAccess = true
            vm.isModInstalled = true
            vm.isFactorioRunning = true
            return vm
        }(),
        grantAccess: nil
    )
}


