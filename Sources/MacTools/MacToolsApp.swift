import Cocoa

@main
final class MacToolsApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let statusProvider = StatusProvider()

    private let timeItem = NSMenuItem(title: "Time: --", action: nil, keyEquivalent: "")
    private let batteryItem = NSMenuItem(title: "Battery: --", action: nil, keyEquivalent: "")
    private let wifiItem = NSMenuItem(title: "Wi-Fi: --", action: nil, keyEquivalent: "")
    private let clipboardItem = NSMenuItem(title: "Clipboard: --", action: nil, keyEquivalent: "")

    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        buildMenu()
        startRefreshTimer()
        updateDynamicItems()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateDynamicItems()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "hammer.circle.fill", accessibilityDescription: "MacTools")
            button.image?.isTemplate = true
            button.toolTip = "MacTools"
        }
        statusItem.menu = menu
    }

    private func buildMenu() {
        menu.autoenablesItems = false
        menu.delegate = self

        let header = NSMenuItem(title: "MacTools", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        timeItem.isEnabled = false
        batteryItem.isEnabled = false
        wifiItem.isEnabled = false
        clipboardItem.isEnabled = false
        menu.addItem(timeItem)
        menu.addItem(batteryItem)
        menu.addItem(wifiItem)
        menu.addItem(clipboardItem)
        menu.addItem(.separator())

        menu.addItem(makeItem("Open Wi-Fi Settings...", #selector(openWiFiSettings)))
        menu.addItem(makeItem("Open Bluetooth Settings...", #selector(openBluetoothSettings)))
        menu.addItem(makeItem("Open Sound Settings...", #selector(openSoundSettings)))
        menu.addItem(makeItem("Open Focus Settings...", #selector(openFocusSettings)))
        menu.addItem(makeItem("Open Displays Settings...", #selector(openDisplaysSettings)))
        menu.addItem(makeItem("Open Keyboard Settings...", #selector(openKeyboardSettings)))
        menu.addItem(makeItem("Open Battery Settings...", #selector(openBatterySettings)))
        menu.addItem(makeItem("Open Date & Time Settings...", #selector(openDateTimeSettings)))
        menu.addItem(.separator())

        menu.addItem(makeItem("Open Calendar", #selector(openCalendar)))
        menu.addItem(makeItem("Open Clock", #selector(openClock)))
        menu.addItem(makeItem("Open Screenshot Tool", #selector(openScreenshotTool)))
        menu.addItem(makeItem("Trigger Spotlight (Cmd+Space)", #selector(triggerSpotlight)))
        menu.addItem(makeItem("Clear Clipboard", #selector(clearClipboard)))
        menu.addItem(.separator())

        menu.addItem(makeItem("Restart Finder", #selector(restartFinder)))
        menu.addItem(makeItem("Relaunch MacTools", #selector(relaunchApp)))
        menu.addItem(.separator())

        menu.addItem(makeItem("Quit", #selector(quitApp), key: "q"))
    }

    private func makeItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateDynamicItems()
        }
    }

    private func updateDynamicItems() {
        timeItem.title = statusProvider.timeStatus()
        batteryItem.title = statusProvider.batteryStatus()
        wifiItem.title = statusProvider.wifiStatus()
        clipboardItem.title = statusProvider.clipboardStatus()
    }

    @objc private func openWiFiSettings() { SystemSettings.open(paneID: SystemSettingsPane.wifi) }
    @objc private func openBluetoothSettings() { SystemSettings.open(paneID: SystemSettingsPane.bluetooth) }
    @objc private func openSoundSettings() { SystemSettings.open(paneID: SystemSettingsPane.sound) }
    @objc private func openFocusSettings() { SystemSettings.open(paneID: SystemSettingsPane.focus) }
    @objc private func openDisplaysSettings() { SystemSettings.open(paneID: SystemSettingsPane.displays) }
    @objc private func openKeyboardSettings() { SystemSettings.open(paneID: SystemSettingsPane.keyboard) }
    @objc private func openBatterySettings() { SystemSettings.open(paneID: SystemSettingsPane.battery) }
    @objc private func openDateTimeSettings() { SystemSettings.open(paneID: SystemSettingsPane.dateTime) }

    @objc private func openCalendar() { AppLauncher.openApp(at: AppPaths.calendar) }
    @objc private func openClock() { AppLauncher.openApp(at: AppPaths.clock) }
    @objc private func openScreenshotTool() { AppLauncher.openApp(at: AppPaths.screenshot) }

    @objc private func triggerSpotlight() {
        ScriptRunner.runAppleScript("tell application \"System Events\" to keystroke space using command down")
    }

    @objc private func clearClipboard() {
        statusProvider.clearClipboard()
        updateDynamicItems()
    }

    @objc private func restartFinder() { ProcessRunner.run("/usr/bin/killall", ["Finder"]) }

    @objc private func relaunchApp() { Relauncher.relaunch() }
    @objc private func quitApp() { NSApp.terminate(nil) }
}
