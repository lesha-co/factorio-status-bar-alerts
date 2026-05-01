import Combine
import Foundation

class ViewModel: ObservableObject {
    @Published var alerts: [FactorioAlert: Int] = [:]
    @Published var blink: Bool = false
    @Published var hasAccess: Bool = false
    @Published var isModInstalled: Bool = false
    @Published var isFactorioRunning: Bool = false
}
