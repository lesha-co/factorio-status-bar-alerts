import AppKit
import SwiftUI

let factorioAppSupportURL = URL(
    filePath: NSString("~/Library/Application Support/factorio/")
        .expandingTildeInPath)

let factorioLogFile = "script-output/macos-status-bar-alerts/alerts.log"
let factorioModsDir = "mods"

class AppDelegate: NSObject, NSApplicationDelegate {
    private var popover = NSPopover()
    private var buttons: [FactorioAlert: NSStatusItem] = [:]
    private var aboutWindow: NSWindow?
    private var logURL: URL?
    let viewModel = ViewModel()
    /// Keeps the security-scoped resource alive for the lifetime of the app.
    private var securityScopedURL: URL?
    func showAbout() {
        if let existing = aboutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingController(rootView: AboutView())
        let window = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingView
        window.title = "About"
        window.isReleasedWhenClosed = false
        window.setContentSize(hostingView.view.fittingSize)
        window.center()
        window.makeKeyAndOrderFront(nil)
        aboutWindow = window
    }

    // MARK: - Buttons
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
    private func setButtonBlink(button: NSStatusBarButton, alert: FactorioAlert) {
        let isAcknowledged = viewModel.acknowledgedAlerts[alert] != nil
        if isAcknowledged {
            // Acknowledged: static muted appearance, no blinking
            button.layer?.backgroundColor = button.layer?.backgroundColor?.copy(alpha: 0.2)
        } else {
            // Normal: blink between 0.2 and 1.0
            button.layer?.backgroundColor = button.layer?.backgroundColor?.copy(
                alpha: self.viewModel.blink ? 0.2 : 1.0)
        }
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
                let symbolConfig = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
                let image = NSImage(
                    systemSymbolName: _icon.name,
                    accessibilityDescription: "Factorio"
                )?.withSymbolConfiguration(symbolConfig)
                button.image = image
                button.imagePosition = .imageLeading
                button.wantsLayer = true
                button.layer?.backgroundColor = NSColor(_icon.statusBarButtonContentTintColor).cgColor
                button.layer?.cornerRadius = 4
                button.layer?.masksToBounds = true
                setButtonBlink(button: button, alert: alert)
            }

            buttons[alert] = statusItem
            return statusItem
        }

    }
    private func startBlinking() {
        let schedule = {
            self.blinkTimer?.invalidate()

            self.blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.viewModel.blink.toggle()
                self.updateIsFactorioRunning()
                self.updateIsModInstalled()

                if self.viewModel.isFactorioRunning {
                    for (alert, statusItem) in self.buttons {
                        guard let button = statusItem.button else { continue }
                        self.setButtonBlink(button: button, alert: alert)
                    }
                } else {
                    self.removeButtons()
                }
            }
        }

        if Thread.isMainThread {
            schedule()
        } else {
            DispatchQueue.main.async(execute: schedule)
        }
    }
    func removeButtons() {
        for (_, statusItem) in buttons {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        buttons.removeAll()
        viewModel.alerts = [:]
        viewModel.acknowledgedAlerts = [:]
    }

    // MARK: - Other
    private func setAlerts(alerts: [FactorioAlert: Int]) {
        DispatchQueue.main.async { [self] in
            self.viewModel.alerts = alerts
            for (alert, count) in alerts {
                // Un-acknowledge if the count changed since acknowledgment
                if let ackCount = self.viewModel.acknowledgedAlerts[alert], ackCount != count {
                    self.viewModel.acknowledgedAlerts.removeValue(forKey: alert)
                }
                let statusItem = self.getOrCreateButton(alert: alert, count: count)
                if count == 0 {
                    guard let btn = statusItem else { continue }
                    NSStatusBar.system.removeStatusItem(btn)
                    self.buttons[alert] = nil
                    self.viewModel.acknowledgedAlerts.removeValue(forKey: alert)
                } else {
                    statusItem?.button?.title = "\(count)"
                }
            }
        }
    }
    private func updateIsFactorioRunning() {
        let runningApps = NSWorkspace.shared.runningApplications
        let appIdentifiers = runningApps.map { ($0.bundleIdentifier) }
        let factorioRunning = appIdentifiers.contains("com.factorio")
        self.viewModel.isFactorioRunning = factorioRunning
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

        guard !trimmed.isEmpty else {
            self.setAlerts(alerts: [:])
            return
        }

        let components = trimmed.components(separatedBy: ",").filter { !$0.isEmpty }

        guard Int(components[0]) != nil else {
            print("Failed to parse tick: \(components[0])")
            return
        }

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
            onHasAccess(bookmark: url)
        }
    }
    func getModsDirectory(baseURL: URL) -> URL {
        return baseURL.appendingPathComponent(factorioModsDir)
    }

    func updateFromLogFile() {
        guard let logURL = self.logURL else { return }
        guard let result = try? String(contentsOf: logURL, encoding: .utf8) else { return }
        self.onFileChange(data: result)
    }

    func revokeAccess() {
        resetBookmark(securityScopedURL: securityScopedURL)
        securityScopedURL = nil
        fileSource?.cancel()
        fileSource = nil
        viewModel.hasAccess = false
        viewModel.isModInstalled = false
        removeButtons()
    }
    func openFactorioFolder() {
        guard let securityScopedURL else {
            print("No base URL set")
            return
        }
        let modsURL = getModsDirectory(baseURL: securityScopedURL)
        NSWorkspace.shared.open(modsURL)
    }

    // MARK: - Mods
    func deleteMod() {
        guard let securityScopedURL else {
            print("No base URL set")
            return
        }
        let modsURL = getModsDirectory(baseURL: securityScopedURL)
        let fm = FileManager.default
        let destinationURL = modsURL.appendingPathComponent(modName)
        do {
            if fm.fileExists(atPath: destinationURL.path) {
                try fm.removeItem(at: destinationURL)
                print("Deleted mod at \(destinationURL.path)")
                DispatchQueue.main.async {
                    self.updateIsModInstalled()
                }
            } else {
                print("Mod not found at \(destinationURL.path)")
            }
        } catch {
            print("Failed to delete mod: \(error)")
        }
    }
    func installMod() {
        guard let securityScopedURL else {
            print("No base URL set")
            return
        }
        let modsURL = getModsDirectory(baseURL: securityScopedURL)
        guard let modSourceURL = Bundle.main.url(forResource: modName, withExtension: nil) else {
            return
        }
        let destinationURL = modsURL.appendingPathComponent(modName)
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: destinationURL.path) {
                try fm.removeItem(at: destinationURL)
            }
            try fm.copyItem(at: modSourceURL, to: destinationURL)
            print("Installed mod to \(destinationURL.path)")
            DispatchQueue.main.async {
                self.updateIsModInstalled()
            }
        } catch {
            print("Failed to install mod: \(error)")
        }
    }
    private func updateIsModInstalled() {
        guard let baseURL = self.securityScopedURL else { return }
        let modsURL = getModsDirectory(baseURL: baseURL)
        let fm = FileManager.default
        do {
            let contents = try fm.contentsOfDirectory(atPath: modsURL.path)
            let found = contents.contains { $0.hasPrefix(modName) }
            DispatchQueue.main.async {
                self.viewModel.isModInstalled = found
            }
            if !found {
                print("Mod '\(modName)' not found in \(modsURL.path)")
            }
        } catch {
            print("Failed to list mods directory: \(error)")
            DispatchQueue.main.async {
                self.viewModel.isModInstalled = false
            }
        }
    }
    // MARK: - Access
    func grantAccess() {
        requestAccessToAppSupport(directoryURL: factorioAppSupportURL) { [weak self] url in
            guard let self, let url else {
                return
            }
            self.onHasAccess(bookmark: url)
        }
    }
    func onHasAccess(bookmark: URL) {
        self.securityScopedURL = bookmark
        self.viewModel.hasAccess = true
        let logURL = bookmark.appendingPathComponent(factorioLogFile)
        self.logURL = logURL

        updateIsModInstalled()

        monitorFile(fileURL: logURL) {
            self.updateFromLogFile()
        }
    }

    // MARK: - Popover
    @objc func togglePopover(_ sender: Any?) {
        guard let clickedButton = sender as? NSStatusBarButton else { return }
        for (alert, statusItem) in buttons {
            if statusItem.button == clickedButton {
                if let count = viewModel.alerts[alert], count > 0 {
                    viewModel.acknowledgedAlerts[alert] = count
                    self.setButtonBlink(button: clickedButton, alert: alert)
                }
                break
            }
        }
    }
}
