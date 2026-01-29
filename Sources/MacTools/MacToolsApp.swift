import Cocoa

final class ActionPayload: NSObject {
    let type: MenuItemType
    let paneID: String?
    let url: String?
    let path: String?
    let command: String?
    let arguments: [String]?
    let script: String?
    let text: String?

    init(
        type: MenuItemType,
        paneID: String? = nil,
        url: String? = nil,
        path: String? = nil,
        command: String? = nil,
        arguments: [String]? = nil,
        script: String? = nil,
        text: String? = nil
    ) {
        self.type = type
        self.paneID = paneID
        self.url = url
        self.path = path
        self.command = command
        self.arguments = arguments
        self.script = script
        self.text = text
    }
}

final class MacToolsApp: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let statusProvider = StatusProvider()
    private let configManager = ConfigManager.shared

    private var config: Config = .fallback

    private var timeItem: NSMenuItem?
    private var batteryItem: NSMenuItem?
    private var wifiItem: NSMenuItem?
    private var clipboardItem: NSMenuItem?

    private var refreshTimer: Timer?
    private var debugWindow: NSWindow?

    private var displayTitle: String {
        let trimmed = config.appTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "MacTools" : trimmed
    }

    private var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private var shouldShowDebugWindow: Bool {
        let envFlag = ProcessInfo.processInfo.environment["MACTOOLS_DEBUG"] == "1"
        return isDebugBuild || envFlag || config.debug.showWindow
    }

    private var shouldShowDebugAlert: Bool {
        ProcessInfo.processInfo.environment["MACTOOLS_DEBUG_ALERT"] == "1"
    }

    private func debugLog(_ message: String) {
        guard shouldShowDebugWindow || shouldShowDebugAlert else { return }
        fputs("[MacTools] \(message)\n", stderr)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        config = configManager.loadConfig()
        statusProvider.updateTimeFormat(config.statusSection.timeFormat)
        if shouldShowDebugWindow {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }

        debugLog("Launch. debugWindow=\(shouldShowDebugWindow) debugAlert=\(shouldShowDebugAlert)")

        setupStatusItem()
        buildMenu()
        startRefreshTimer()
        updateDynamicItems()
        if shouldShowDebugWindow {
            showDebugWindow()
        }
        if shouldShowDebugAlert {
            showDebugAlert()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateDynamicItems()
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == debugWindow {
            debugWindow = nil
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        applyMenuBarIcon()
        statusItem.menu = menu
    }

    private func applyMenuBarIcon() {
        guard let button = statusItem.button else { return }
        let icon = resolveMenuBarIcon()
        button.image = icon
        button.image?.isTemplate = true
        button.toolTip = config.menuBarIcon.accessibilityLabel ?? displayTitle
        if icon == nil {
            button.title = displayTitle
        } else {
            button.title = ""
        }
    }

    private func resolveMenuBarIcon() -> NSImage? {
        if let iconPath = config.menuBarIcon.iconPath, !iconPath.isEmpty {
            let baseURL = configManager.configDirectory()
            let resolved = URL(fileURLWithPath: iconPath, relativeTo: baseURL).standardizedFileURL
            if FileManager.default.fileExists(atPath: resolved.path),
               let image = NSImage(contentsOf: resolved) {
                image.isTemplate = true
                return image
            }
        }

        if let symbolName = config.menuBarIcon.symbolName, !symbolName.isEmpty {
            return NSImage(systemSymbolName: symbolName, accessibilityDescription: config.menuBarIcon.accessibilityLabel)
        }

        return NSImage(systemSymbolName: "hammer.circle.fill", accessibilityDescription: displayTitle)
    }

    private func buildMenu() {
        menu.autoenablesItems = false
        menu.delegate = self
        menu.removeAllItems()

        timeItem = nil
        batteryItem = nil
        wifiItem = nil
        clipboardItem = nil

        let header = NSMenuItem(title: displayTitle, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        addStatusSection()

        for section in config.sections {
            addMenuSection(section)
        }

        addFooterSection()
    }

    private func addStatusSection() {
        let status = config.statusSection
        let hasAny = status.showTime || status.showBattery || status.showWiFi || status.showClipboard
        guard hasAny else { return }

        if !status.title.isEmpty {
            let titleItem = NSMenuItem(title: status.title, action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)
        }

        if status.showTime {
            let item = NSMenuItem(title: "Time: --", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            timeItem = item
        }

        if status.showBattery {
            let item = NSMenuItem(title: "Battery: --", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            batteryItem = item
        }

        if status.showWiFi {
            let item = NSMenuItem(title: "Wi-Fi: --", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            wifiItem = item
        }

        if status.showClipboard {
            let item = NSMenuItem(title: "Clipboard: --", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            clipboardItem = item
        }

        menu.addItem(.separator())
    }

    private func addMenuSection(_ section: MenuSection) {
        guard !section.items.isEmpty else { return }
        if let title = section.title, !title.isEmpty {
            let titleItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)
        }

        for item in section.items {
            if let menuItem = makeConfiguredMenuItem(item) {
                menu.addItem(menuItem)
            }
        }

        menu.addItem(.separator())
    }

    private func addFooterSection() {
        let footer = config.footer
        if footer.showReloadConfig {
            menu.addItem(makeConfiguredMenuItem(MenuItemConfig(type: .reloadConfig, title: "Reload Config"))!)
        }
        if footer.showOpenConfig {
            menu.addItem(makeConfiguredMenuItem(MenuItemConfig(type: .openConfig, title: "Open Config"))!)
        }
        if footer.showRevealConfig {
            menu.addItem(makeConfiguredMenuItem(MenuItemConfig(type: .revealConfig, title: "Reveal Config in Finder"))!)
        }
        if footer.showRelaunch {
            menu.addItem(makeConfiguredMenuItem(MenuItemConfig(type: .relaunch, title: "Relaunch MacTools"))!)
        }
        if footer.showQuit {
            menu.addItem(makeConfiguredMenuItem(MenuItemConfig(type: .quit, title: "Quit"))!)
        }
    }

    private func makeConfiguredMenuItem(_ item: MenuItemConfig) -> NSMenuItem? {
        if item.type == .separator {
            return .separator()
        }

        let title = item.title?.isEmpty == false ? item.title! : defaultTitle(for: item.type)
        let menuItem = NSMenuItem(title: title, action: #selector(handleConfiguredAction(_:)), keyEquivalent: item.keyEquivalent ?? "")
        menuItem.target = self
        menuItem.isEnabled = item.enabled ?? true
        menuItem.representedObject = ActionPayload(
            type: item.type,
            paneID: item.paneID,
            url: item.url,
            path: item.path,
            command: item.command,
            arguments: item.arguments,
            script: item.script,
            text: item.text
        )
        return menuItem
    }

    private func defaultTitle(for type: MenuItemType) -> String {
        switch type {
        case .openSettings: return "Open Settings"
        case .openApp: return "Open App"
        case .openURL: return "Open URL"
        case .shell: return "Run Command"
        case .appleScript: return "Run AppleScript"
        case .clipboardCopy: return "Copy to Clipboard"
        case .clipboardClear: return "Clear Clipboard"
        case .reloadConfig: return "Reload Config"
        case .openConfig: return "Open Config"
        case .revealConfig: return "Reveal Config in Finder"
        case .relaunch: return "Relaunch MacTools"
        case .quit: return "Quit"
        case .separator: return ""
        }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateDynamicItems()
        }
    }

    private func updateDynamicItems() {
        if let timeItem {
            timeItem.title = statusProvider.timeStatus()
        }
        if let batteryItem {
            batteryItem.title = statusProvider.batteryStatus()
        }
        if let wifiItem {
            wifiItem.title = statusProvider.wifiStatus()
        }
        if let clipboardItem {
            clipboardItem.title = statusProvider.clipboardStatus()
        }
    }

    private func showDebugWindow() {
        if let debugWindow {
            debugWindow.makeKeyAndOrderFront(nil)
            debugWindow.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 280),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(displayTitle) Debug"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .moveToActiveSpace, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.center()
        window.delegate = self

        let contentView = NSView()
        window.contentView = contentView

        let titleLabel = NSTextField(labelWithString: "\(displayTitle) is running")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let infoLabel = NSTextField(labelWithString: "This is a menu-bar-only app. The icon appears on the primary display’s menu bar.")
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.maximumNumberOfLines = 0

        let hintLabel = NSTextField(labelWithString: "Tip: disable menu bar auto-hide or free up space if you don’t see the icon.")
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.maximumNumberOfLines = 0

        let reloadButton = NSButton(title: "Reload Config", target: self, action: #selector(reloadConfigFromDebug))
        let openButton = NSButton(title: "Open Config", target: self, action: #selector(openConfigFromDebug))
        let revealButton = NSButton(title: "Reveal in Finder", target: self, action: #selector(revealConfigFromDebug))
        let relaunchButton = NSButton(title: "Relaunch", target: self, action: #selector(relaunchFromDebug))
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quitFromDebug))

        let buttonStack = NSStackView(views: [reloadButton, openButton, revealButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8

        let buttonStack2 = NSStackView(views: [relaunchButton, quitButton])
        buttonStack2.orientation = .horizontal
        buttonStack2.spacing = 8

        let stack = NSStackView(views: [titleLabel, infoLabel, hintLabel, buttonStack, buttonStack2])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20)
        ])

        debugWindow = window
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.debugWindow?.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showDebugAlert() {
        let alert = NSAlert()
        alert.messageText = "\(displayTitle) Debug"
        alert.informativeText = "MacTools launched in debug mode. This confirms the app is running."
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func reloadConfigFromDebug() {
        reloadConfig()
    }

    @objc private func openConfigFromDebug() {
        configManager.openConfig()
    }

    @objc private func revealConfigFromDebug() {
        configManager.revealConfigInFinder()
    }

    @objc private func relaunchFromDebug() {
        Relauncher.relaunch()
    }

    @objc private func quitFromDebug() {
        NSApp.terminate(nil)
    }

    @objc private func handleConfiguredAction(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? ActionPayload else { return }

        switch payload.type {
        case .openSettings:
            SystemSettings.open(paneID: payload.paneID)
        case .openApp:
            if let path = payload.path { AppLauncher.openApp(at: path) }
        case .openURL:
            if let url = payload.url { URLLauncher.open(url) }
        case .shell:
            if let command = payload.command {
                ProcessRunner.run(command, payload.arguments ?? [])
            }
        case .appleScript:
            if let script = payload.script { ScriptRunner.runAppleScript(script) }
        case .clipboardCopy:
            if let text = payload.text {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(text, forType: .string)
            }
        case .clipboardClear:
            statusProvider.clearClipboard()
            updateDynamicItems()
        case .reloadConfig:
            reloadConfig()
        case .openConfig:
            configManager.openConfig()
        case .revealConfig:
            configManager.revealConfigInFinder()
        case .relaunch:
            Relauncher.relaunch()
        case .quit:
            NSApp.terminate(nil)
        case .separator:
            break
        }
    }

    private func reloadConfig() {
        config = configManager.loadConfig()
        statusProvider.updateTimeFormat(config.statusSection.timeFormat)
        applyMenuBarIcon()
        buildMenu()
        updateDynamicItems()
        if shouldShowDebugWindow {
            showDebugWindow()
        } else {
            debugWindow?.close()
            debugWindow = nil
        }
    }
}

@main
struct MacToolsMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = MacToolsApp()
        app.delegate = delegate
        app.run()
    }
}
