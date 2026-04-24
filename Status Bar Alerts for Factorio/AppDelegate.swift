import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var popover = NSPopover()
    private var buttons: [FactorioAlert: NSStatusItem] = [:]
    let viewModel = ViewModel()

    private var alertActive: Bool = false
    private var blinkTimer: Timer?

    private func createButton() -> NSStatusItem? {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover(_:))
            button.target = self
            return statusItem
        }

        return nil

    }

    private func getOrCreateButton(alert: FactorioAlert, count: Int) -> NSStatusItem? {

        if let currentData = buttons[alert] {
            return currentData
        } else {
            guard let statusItem = createButton() else {
                print("Failed to create button \(alert)")
                return nil
            }
            let _icon = icon(alert)

            if let button = statusItem.button {
                button.image = NSImage(
                    systemSymbolName: _icon.name,
                    accessibilityDescription: "Factorio"
                )
                button.wantsLayer = true
                button.layer?.backgroundColor = NSColor(_icon.color).cgColor
                button.layer?.cornerRadius = 4
                button.layer?.masksToBounds = true
                button.appearsDisabled = self.alertActive
            }

            buttons[alert] = statusItem
            return statusItem
        }

    }

    private func setAlerts(alerts: [FactorioAlert: Int]) {
        self.viewModel.alerts = alerts
        for (alert, count) in alerts {
            let statusItem = getOrCreateButton(alert: alert, count: count)
            if count == 0 {
                guard let btn = statusItem else { continue }
                NSStatusBar.system.removeStatusItem(btn)
                buttons[alert] = nil
            } else {
                statusItem?.button?.title = "\(count)"
            }

        }

    }

    private func startBlinking() {
        guard blinkTimer == nil else { return }

        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.alertActive.toggle()

            for (_, statusItem) in self.buttons {

                guard let button = statusItem.button else { continue }
                DispatchQueue.main.async {
                    button.appearsDisabled = self.alertActive
                }
            }
        }

    }

    func onFileChange(data: String) {
        let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DispatchQueue.main.async {
                self.setAlerts(alerts: [:])
            }
            return
        }

        // Format: {username},{alert_kind}:{alert_count}
        let components = trimmed.components(separatedBy: ",")
        guard components.count >= 2 else {
            print("Invalid data format: \(trimmed)")
            return
        }

        var alerts: [FactorioAlert: Int] = Dictionary(
            uniqueKeysWithValues: FactorioAlert.allCases.map { ($0, 0) })
        // Skip first component (username), parse remaining alert pairs
        for i in 1..<components.count {
            let pair = components[i].components(separatedBy: ":")
            guard pair.count == 2,
                let alertId = Int(pair[0]),
                let alertCount = Int(pair[1]),
                let alert = FactorioAlert(rawValue: alertId)
            else {
                print("Failed to parse alert pair: \(components[i])")
                continue
            }
            alerts[alert] = alertCount
        }

        DispatchQueue.main.async {
            self.setAlerts(alerts: alerts)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            return
        }

        // configure popover content
        popover.contentSize = NSSize(width: 100, height: 100)
        // popover.contentViewController = NSHostingController(rootView: MenuContentView())
        startBlinking()

        monitorFile(
            filename: NSString("~/Library/Application Support/factorio/script-output/alerts.log")
                .expandingTildeInPath
        ) { result in
            self.onFileChange(data: result)
        }

    }

    @objc func togglePopover(_ sender: Any?) {
        //        guard let button = statusItem?.button else { return }
        //        if popover.isShown {
        //            popover.performClose(sender)
        //        } else {
        //            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        //            popover.contentViewController?.view.window?.becomeKey()
        //        }
    }
}
