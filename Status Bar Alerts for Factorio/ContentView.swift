import SwiftUI

struct ContentView: View {
    var vm: ViewModel

    var body: some View {
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

#Preview {
    ContentView(
        vm: {
            let vm = ViewModel()
            vm.alerts = [
                .entity_destroyed: 12,
                .no_storage: 5
            ]
            vm.hasAccess = false
            return vm
        }()
    )
}
