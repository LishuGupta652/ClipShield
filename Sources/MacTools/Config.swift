import Cocoa

struct Config: Codable {
    var version: Int
    var menuBarIcon: MenuBarIcon
    var statusSection: StatusSection
    var sections: [MenuSection]
    var footer: Footer

    static let fallback: Config = {
        Config(
            version: 1,
            menuBarIcon: MenuBarIcon(symbolName: "hammer.circle.fill", iconPath: nil, accessibilityLabel: "MacTools"),
            statusSection: StatusSection(
                title: "Status",
                showTime: true,
                showBattery: true,
                showWiFi: true,
                showClipboard: true,
                timeFormat: "EEE, MMM d h:mm a"
            ),
            sections: [],
            footer: Footer(showReloadConfig: true, showOpenConfig: true, showRevealConfig: true, showRelaunch: true, showQuit: true)
        )
    }()
}

struct MenuBarIcon: Codable {
    var symbolName: String?
    var iconPath: String?
    var accessibilityLabel: String?
}

struct StatusSection: Codable {
    var title: String
    var showTime: Bool
    var showBattery: Bool
    var showWiFi: Bool
    var showClipboard: Bool
    var timeFormat: String?
}

struct MenuSection: Codable {
    var title: String?
    var items: [MenuItemConfig]
}

struct MenuItemConfig: Codable {
    var type: MenuItemType
    var title: String?
    var paneID: String?
    var url: String?
    var path: String?
    var command: String?
    var arguments: [String]?
    var script: String?
    var text: String?
    var enabled: Bool?
    var keyEquivalent: String?
}

enum MenuItemType: String, Codable {
    case openSettings
    case openApp
    case openURL
    case shell
    case appleScript
    case clipboardCopy
    case clipboardClear
    case reloadConfig
    case openConfig
    case revealConfig
    case relaunch
    case quit
    case separator
}

struct Footer: Codable {
    var showReloadConfig: Bool
    var showOpenConfig: Bool
    var showRevealConfig: Bool
    var showRelaunch: Bool
    var showQuit: Bool
}

final class ConfigManager {
    static let shared = ConfigManager()

    private let fileManager = FileManager.default
    private let appSupportURL: URL
    private let configURL: URL

    init() {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        appSupportURL = base.appendingPathComponent("MacTools", isDirectory: true)
        configURL = appSupportURL.appendingPathComponent("config.json")
    }

    func ensureUserConfig() {
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: configURL.path) {
            if let defaultURL = Bundle.main.url(forResource: "DefaultConfig", withExtension: "json"),
               let data = try? Data(contentsOf: defaultURL) {
                try? data.write(to: configURL, options: [.atomic])
            } else if let data = try? JSONEncoder().encode(Config.fallback) {
                try? data.write(to: configURL, options: [.atomic])
            }
        }
    }

    func loadConfig() -> Config {
        ensureUserConfig()

        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(Config.self, from: data) {
            return config
        }

        if let data = try? JSONEncoder().encode(Config.fallback) {
            try? data.write(to: configURL, options: [.atomic])
        }

        return Config.fallback
    }

    func configFileURL() -> URL {
        ensureUserConfig()
        return configURL
    }

    func configDirectory() -> URL {
        appSupportURL
    }

    func openConfig() {
        let url = configFileURL()
        NSWorkspace.shared.open(url)
    }

    func revealConfigInFinder() {
        let url = configFileURL()
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
