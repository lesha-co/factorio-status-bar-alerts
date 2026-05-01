import SwiftUI

struct AlertIconView: View {
    let alert: FactorioAlert
    let count: Int
    let blink: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let i = icon(alert)
        HStack(alignment: .bottom) {
            Image(systemName: i.name).foregroundColor(
                colorScheme == .dark ? i.color : i.UILightThemeColor
            )
            .font(.system(size: 32))
            .frame(width: 40)
            Text("\(count)").font(.system(size: 16))
        }
        .opacity((count > 0 && blink == false) ? 1 : 0.1)
    }
}
struct MainView: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(FactorioAlert.allCases, id: \.self) { alert in
                    AlertIconView(
                        alert: alert,
                        count: vm.alerts[alert] ?? 0,
                        blink: vm.blink
                    )
                }
            }
            Button {
                if let url = URL(string: "https://lesha.co/support") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image(systemName: "heart.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.accentColor)
                Text("Consider donating")
            }

        }.padding()
    }
}

struct ContentView: View {
    @ObservedObject var vm: ViewModel
    var grantAccess: (() -> Void)?
    var onModInstall: (() -> Void)?

    private var mode: Bool { vm.hasAccess && vm.isModInstalled && vm.isFactorioRunning }

    func openModWebsite() {
        if let url = URL(string: "https://mods.factorio.com/mod/" + modName) {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        Group {
            if mode {
                MainView(vm: vm)
            } else {
                ErrorContent(
                    folderAccess: vm.hasAccess,
                    modInstalled: vm.isModInstalled,
                    onRequestFolderAccess: grantAccess,
                    onRequestModInstallation: onModInstall,
                    onRequestOpenFactorioModWebsite: openModWebsite,
                )
            }
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
