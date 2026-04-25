import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: ViewModel
    var grantAccess: (() -> Void)?

    var body: some View {
        if vm.hasAccess {
            Text(vm.isFactorioRunning ? "Factorio is running" : "Factorio is not running")
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
        } else {
            VStack(spacing: 12) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)

                Text("Folder access is required to monitor Factorio alerts.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Button("Grant Folder Access") {
                    grantAccess?()
                }
                .controlSize(.large)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            return vm
        }(),
        grantAccess: nil
    )
}
