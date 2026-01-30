import AppKit
import ClipShieldCore

final class ClipShieldApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let detector = PIIDetector()
    private let redactor = Redactor()
    private let configManager = ConfigManager.shared

    private var config: AppConfig = .fallback
    private var logger: EventLogger?
    private var monitor: ClipboardMonitor?

    private var lastDetection: DetectionResult = DetectionResult(matches: [], textLength: 0)
    private var lastScanDate: Date?
    private var lastAction: String?
    private var lastPreview: String?

    private var monitoringToggleItem: NSMenuItem?
    private var safePasteToggleItem: NSMenuItem?
    private var lastScanItem: NSMenuItem?
    private var lastFindingItem: NSMenuItem?
    private var lastActionItem: NSMenuItem?
    private var clipboardPreviewItem: NSMenuItem?
    private var redactItem: NSMenuItem?
    private var tokenizeItem: NSMenuItem?

    private var displayTitle: String {
        let trimmed = config.appTitle.trimmed()
        return trimmed.isEmpty ? "ClipShield" : trimmed
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        config = configManager.loadConfig()
        logger = EventLogger(config: config.logging, fileURL: configManager.logFileURL(fileName: config.logging.fileName))

        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        buildMenu()
        startMonitoringIfNeeded()
        refreshClipboardSnapshot()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshClipboardSnapshot()
        updateMenuState()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        applyMenuBarIcon(alert: false)
        statusItem.menu = menu
    }

    private func applyMenuBarIcon(alert: Bool) {
        guard let button = statusItem.button else { return }
        let icon = resolveMenuBarIcon(alert: alert)
        button.image = icon
        button.image?.isTemplate = true
        button.toolTip = config.menuBarIcon.accessibilityLabel ?? displayTitle
        if icon == nil {
            button.title = displayTitle
        } else {
            button.title = ""
        }
    }

    private func resolveMenuBarIcon(alert: Bool) -> NSImage? {
        if let iconPath = config.menuBarIcon.iconPath, !iconPath.isEmpty {
            let baseURL = configManager.configDirectory()
            let resolved = URL(fileURLWithPath: iconPath, relativeTo: baseURL).standardizedFileURL
            if FileManager.default.fileExists(atPath: resolved.path),
               let image = NSImage(contentsOf: resolved) {
                image.isTemplate = true
                return image
            }
        }

        let symbolName = alert ? config.menuBarIcon.alertSymbolName : config.menuBarIcon.symbolName
        if let symbolName, !symbolName.isEmpty {
            return NSImage(systemSymbolName: symbolName, accessibilityDescription: config.menuBarIcon.accessibilityLabel)
        }

        return NSImage(systemSymbolName: "shield.lefthalf.filled", accessibilityDescription: displayTitle)
    }

    private func buildMenu() {
        menu.autoenablesItems = false
        menu.delegate = self
        menu.removeAllItems()

        let header = NSMenuItem(title: displayTitle, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let monitoringItem = NSMenuItem(title: "Monitoring", action: #selector(toggleMonitoring), keyEquivalent: "")
        monitoringItem.target = self
        menu.addItem(monitoringItem)
        monitoringToggleItem = monitoringItem

        let safePasteItem = NSMenuItem(title: "Safe Paste", action: #selector(toggleSafePaste), keyEquivalent: "")
        safePasteItem.target = self
        menu.addItem(safePasteItem)
        safePasteToggleItem = safePasteItem

        let scanItem = NSMenuItem(title: "Last scan: --", action: nil, keyEquivalent: "")
        scanItem.isEnabled = false
        menu.addItem(scanItem)
        lastScanItem = scanItem

        let findingItem = NSMenuItem(title: "Last finding: --", action: nil, keyEquivalent: "")
        findingItem.isEnabled = false
        menu.addItem(findingItem)
        lastFindingItem = findingItem

        let actionItem = NSMenuItem(title: "Last action: --", action: nil, keyEquivalent: "")
        actionItem.isEnabled = false
        menu.addItem(actionItem)
        lastActionItem = actionItem

        let previewItem = NSMenuItem(title: "Clipboard: --", action: nil, keyEquivalent: "")
        previewItem.isEnabled = false
        menu.addItem(previewItem)
        clipboardPreviewItem = previewItem

        menu.addItem(.separator())

        let redactItem = NSMenuItem(title: "Redact Clipboard", action: #selector(redactClipboard), keyEquivalent: "r")
        redactItem.keyEquivalentModifierMask = [.command, .option]
        redactItem.target = self
        menu.addItem(redactItem)
        self.redactItem = redactItem

        let tokenizeItem = NSMenuItem(title: "Tokenize Clipboard", action: #selector(tokenizeClipboard), keyEquivalent: "t")
        tokenizeItem.keyEquivalentModifierMask = [.command, .option]
        tokenizeItem.target = self
        menu.addItem(tokenizeItem)
        self.tokenizeItem = tokenizeItem

        let clearItem = NSMenuItem(title: "Clear Clipboard", action: #selector(clearClipboard), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let reloadItem = NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "")
        reloadItem.target = self
        menu.addItem(reloadItem)

        let openItem = NSMenuItem(title: "Open Config", action: #selector(openConfig), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let revealItem = NSMenuItem(title: "Reveal Config in Finder", action: #selector(revealConfig), keyEquivalent: "")
        revealItem.target = self
        menu.addItem(revealItem)

        let logItem = NSMenuItem(title: "Open Logs", action: #selector(openLogs), keyEquivalent: "")
        logItem.target = self
        menu.addItem(logItem)

        menu.addItem(.separator())

        let relaunchItem = NSMenuItem(title: "Relaunch ClipShield", action: #selector(relaunch), keyEquivalent: "")
        relaunchItem.target = self
        menu.addItem(relaunchItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        updateMenuState()
    }

    private func updateMenuState() {
        monitoringToggleItem?.state = config.monitoring.enabled ? .on : .off
        safePasteToggleItem?.state = config.monitoring.safePaste.enabled ? .on : .off

        if let lastScanDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .none
            lastScanItem?.title = "Last scan: \(formatter.string(from: lastScanDate))"
        } else {
            lastScanItem?.title = "Last scan: --"
        }

        lastFindingItem?.title = "Last finding: \(lastDetection.summary())"
        if let lastAction {
            lastActionItem?.title = "Last action: \(lastAction)"
        } else {
            lastActionItem?.title = "Last action: --"
        }

        if let lastPreview {
            clipboardPreviewItem?.title = "Clipboard: \(lastPreview)"
        } else {
            clipboardPreviewItem?.title = "Clipboard: --"
        }

        let hasPII = !lastDetection.matches.isEmpty
        applyMenuBarIcon(alert: hasPII)
        statusItem.button?.toolTip = hasPII ? "ClipShield: PII detected" : "ClipShield"
    }

    private func startMonitoringIfNeeded() {
        monitor?.stop()
        monitor = ClipboardMonitor()
        monitor?.onTextChange = { [weak self] text in
            self?.handleClipboardChange(text)
        }

        if config.monitoring.enabled {
            monitor?.start(interval: max(0.2, config.monitoring.pollIntervalSeconds))
        }
    }

    private func refreshClipboardSnapshot() {
        guard let text = ClipboardService.readText(), !text.isEmpty else {
            lastPreview = nil
            return
        }
        let detection = detector.detect(in: text, config: config)
        lastDetection = detection
        lastScanDate = Date()
        lastPreview = summarize(text)
        updateMenuState()
    }

    private func handleClipboardChange(_ text: String) {
        let detection = detector.detect(in: text, config: config)
        lastDetection = detection
        lastScanDate = Date()
        lastPreview = summarize(text)

        if !detection.matches.isEmpty {
            logger?.log(event: "pii_detected", metadata: [
                "types": detection.summary(),
                "matches": String(detection.matches.count)
            ])
        }

        if config.monitoring.safePaste.enabled, !detection.matches.isEmpty {
            let mode = redactionMode(from: config.monitoring.safePaste.action)
            let redacted = redactor.redact(text: text, matches: detection.matches, mode: mode, config: config)
            if redacted != text {
                monitor?.suppressNext()
                ClipboardService.writeText(redacted)
                lastAction = "Auto-\(config.monitoring.safePaste.action.rawValue.capitalized)"
                logger?.log(event: "auto_redact", metadata: [
                    "strategy": config.monitoring.safePaste.action.rawValue,
                    "types": detection.summary()
                ])
            }
        }

        updateMenuState()
    }

    private func summarize(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(of: "\n", with: " ").trimmed()
        let maxLength = 60
        if collapsed.count > maxLength {
            return String(collapsed.prefix(maxLength)) + "…"
        }
        return collapsed
    }

    private func redactionMode(from strategy: RedactionStrategy) -> RedactionMode {
        switch strategy {
        case .mask: return .mask
        case .tokenize: return .tokenize
        case .remove: return .remove
        }
    }

    @objc private func toggleMonitoring() {
        config.monitoring.enabled.toggle()
        configManager.saveConfig(config)
        startMonitoringIfNeeded()
        updateMenuState()
    }

    @objc private func toggleSafePaste() {
        config.monitoring.safePaste.enabled.toggle()
        configManager.saveConfig(config)
        updateMenuState()
    }

    @objc private func redactClipboard() {
        guard let text = ClipboardService.readText(), !text.isEmpty else { return }
        let detection = detector.detect(in: text, config: config)
        lastDetection = detection
        if detection.matches.isEmpty {
            lastAction = "No PII found"
            updateMenuState()
            return
        }
        let redacted = redactor.redact(text: text, matches: detection.matches, mode: .mask, config: config)
        monitor?.suppressNext()
        ClipboardService.writeText(redacted)
        lastAction = "Redacted"
        logger?.log(event: "manual_redact", metadata: [
            "types": detection.summary(),
            "matches": String(detection.matches.count)
        ])
        updateMenuState()
    }

    @objc private func tokenizeClipboard() {
        guard let text = ClipboardService.readText(), !text.isEmpty else { return }
        let detection = detector.detect(in: text, config: config)
        lastDetection = detection
        if detection.matches.isEmpty {
            lastAction = "No PII found"
            updateMenuState()
            return
        }
        let tokenized = redactor.redact(text: text, matches: detection.matches, mode: .tokenize, config: config)
        monitor?.suppressNext()
        ClipboardService.writeText(tokenized)
        lastAction = "Tokenized"
        logger?.log(event: "manual_tokenize", metadata: [
            "types": detection.summary(),
            "matches": String(detection.matches.count)
        ])
        updateMenuState()
    }

    @objc private func clearClipboard() {
        ClipboardService.clear()
        lastAction = "Clipboard cleared"
        updateMenuState()
    }

    @objc private func reloadConfig() {
        config = configManager.loadConfig()
        logger = EventLogger(config: config.logging, fileURL: configManager.logFileURL(fileName: config.logging.fileName))
        startMonitoringIfNeeded()
        updateMenuState()
    }

    @objc private func openConfig() {
        configManager.openConfig()
    }

    @objc private func revealConfig() {
        configManager.revealConfigInFinder()
    }

    @objc private func openLogs() {
        configManager.openLogFile(fileName: config.logging.fileName)
    }

    @objc private func relaunch() {
        Relauncher.relaunch()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@main
struct ClipShieldMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = ClipShieldApp()
        app.delegate = delegate
        app.run()
    }
}
