import AppKit
import SwiftUI

let factorioAppSupportURL = URL(
    filePath: NSString("~/Library/Application Support/factorio/")
        .expandingTildeInPath)

let factorioLogFile = "script-output/alerts.log"

class AppDelegate: NSObject, NSApplicationDelegate {

    private var popover = NSPopover()
    private var buttons: [FactorioAlert: NSStatusItem] = [:]
    let viewModel = ViewModel()
    /// Keeps the security-scoped resource alive for the lifetime of the app.
    private var securityScopedURL: URL?

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
        DispatchQueue.main.async { [self] in
            for (alert, count) in alerts {
                let statusItem = self.getOrCreateButton(alert: alert, count: count)
                if count == 0 {
                    guard let btn = statusItem else { continue }
                    NSStatusBar.system.removeStatusItem(btn)
                    self.buttons[alert] = nil
                } else {
                    statusItem?.button?.title = "\(count)"
                }
            }
        }

    }

    private func startBlinking() {
        let schedule = {
            self.blinkTimer?.invalidate()

            self.blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.alertActive.toggle()
                let runningApps = NSWorkspace.shared.runningApplications
                let appIdentifiers = runningApps.map {
                    ($0.bundleIdentifier)
                }
                let factorioRunning = appIdentifiers.contains("com.factorio")
                self.viewModel.isFactorioRunning = factorioRunning

                for (_, statusItem) in self.buttons {
                    guard let button = statusItem.button else { continue }
                    button.appearsDisabled = self.alertActive
                    button.isHidden = !factorioRunning
                }
            }
        }

        if Thread.isMainThread {
            schedule()
        } else {
            DispatchQueue.main.async(execute: schedule)
        }
    }

    func syncTimer(currentTick: Int) {
        // let ticksSinceLastWhole = currentTick % 60
        // let ticksToNextWhole = 60 - ticksSinceLastWhole
        // let secondsToNextWhole = Double(ticksToNextWhole) / 60.0
        DispatchQueue.main.async {
            self.startBlinking()
        }
    }

    func createAlerts(components: [String]) -> [FactorioAlert: Int] {
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
        return alerts
    }

    func onFileChange(data: String) {
        let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)

        let components = trimmed.components(separatedBy: ",")

        guard !trimmed.isEmpty else {
            self.setAlerts(alerts: [:])
            return
        }

        guard let tick = Int(components[0]) else {
            print("Failed to parse tick: \(components[0])")
            return
        }

        syncTimer(currentTick: tick)
        let alerts = createAlerts(components: components)
        self.setAlerts(alerts: alerts)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            return
        }
        // configure popover content
        popover.contentSize = NSSize(width: 100, height: 100)
        // popover.contentViewController = NSHostingController(rootView: MenuContentView())
        startBlinking()
        // Try to restore a previously-saved security bookmark
        if let url = restoreBookmarkAccess() {
            securityScopedURL = url
            self.viewModel.hasAccess = true
            startMonitoring(baseURL: url)
        }
    }

    /// Begin monitoring the Factorio alerts log file.
    private func startMonitoring(baseURL: URL) {
        print("startMonitoring()")
        monitorFile(
            fileURL: baseURL.appendingPathComponent(factorioLogFile)
        ) { result in
            self.onFileChange(data: result)
        }
    }

    /// Called from the UI when the user taps "Grant Access".
    func grantAccess() {
        requestAccessToAppSupport(directoryURL: factorioAppSupportURL) { [weak self] url in
            guard let self, let url else {
                return
            }
            self.securityScopedURL = url
            self.viewModel.hasAccess = true
            self.startMonitoring(baseURL: url)
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
