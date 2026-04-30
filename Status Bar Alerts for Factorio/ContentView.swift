import SwiftUI

struct AlertIconView: View {
    let alert: FactorioAlert
    let count: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let i = icon(alert)
        HStack {
            Image(systemName: i.name).foregroundColor(
                colorScheme == .dark ? i.color : i.UILightThemeColor
            )
            .font(.system(size: 24))
            .frame(width: 40)
            Text("\(count)").font(.system(size: 24))
        }
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
                        count: vm.alerts[alert] ?? 0
                    )
                }
            }
            Button {
                if let url = URL(string: "https://lesha.co/donate") {
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

    func respondToModeChange() {
        guard let window = NSApp.windows.first else { return }
        var frame = window.frame
        frame.size.width = mode ? 400 : 550
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame, display: true)
        }
    }

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
                    onRequestOpenFactorioModWebsite: openModWebsite
                )
            }
        }
        .frame(maxWidth: 550, idealHeight: 200, alignment: .init(horizontal: .center, vertical: .top))
        .onChange(of: mode) {
            respondToModeChange()
        }
        .onAppear() {
            respondToModeChange()
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
