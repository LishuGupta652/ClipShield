import Cocoa

struct Config: Codable {
    var version: Int
    var appTitle: String
    var menuBarIcon: MenuBarIcon
    var statusSection: StatusSection
    var sections: [MenuSection]
    var footer: Footer
    var debug: DebugSettings

    enum CodingKeys: String, CodingKey {
        case version
        case appTitle
        case menuBarIcon
        case statusSection
        case sections
        case footer
        case debug
    }

    init(
        version: Int,
        appTitle: String,
        menuBarIcon: MenuBarIcon,
        statusSection: StatusSection,
        sections: [MenuSection],
        footer: Footer,
        debug: DebugSettings
    ) {
        self.version = version
        self.appTitle = appTitle
        self.menuBarIcon = menuBarIcon
        self.statusSection = statusSection
        self.sections = sections
        self.footer = footer
        self.debug = debug
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        appTitle = try container.decodeIfPresent(String.self, forKey: .appTitle) ?? "MacTools"
        menuBarIcon = try container.decodeIfPresent(MenuBarIcon.self, forKey: .menuBarIcon) ?? .fallback
        statusSection = try container.decodeIfPresent(StatusSection.self, forKey: .statusSection) ?? .fallback
        sections = try container.decodeIfPresent([MenuSection].self, forKey: .sections) ?? []
        footer = try container.decodeIfPresent(Footer.self, forKey: .footer) ?? .fallback
        debug = try container.decodeIfPresent(DebugSettings.self, forKey: .debug) ?? .fallback
    }

    static let fallback: Config = {
        Config(
            version: 1,
            appTitle: "MacTools",
            menuBarIcon: .fallback,
            statusSection: .fallback,
            sections: [],
            footer: .fallback,
            debug: .fallback
        )
    }()
}

struct MenuBarIcon: Codable {
    var symbolName: String?
    var iconPath: String?
    var accessibilityLabel: String?

    static let fallback = MenuBarIcon(symbolName: "hammer.circle.fill", iconPath: nil, accessibilityLabel: "MacTools")
}

struct StatusSection: Codable {
    var title: String
    var showTime: Bool
    var showBattery: Bool
    var showWiFi: Bool
    var showClipboard: Bool
    var timeFormat: String?

    static let fallback = StatusSection(
        title: "Status",
        showTime: true,
        showBattery: true,
        showWiFi: true,
        showClipboard: true,
        timeFormat: "EEE, MMM d h:mm a"
    )
}

struct MenuSection: Codable {
    var title: String?
    var items: [MenuItemConfig]
}

struct MenuItemConfig: Codable {
    var type: MenuItemType
    var title: String? = nil
    var paneID: String? = nil
    var url: String? = nil
    var path: String? = nil
    var command: String? = nil
    var arguments: [String]? = nil
    var script: String? = nil
    var text: String? = nil
    var enabled: Bool? = nil
    var keyEquivalent: String? = nil
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

    static let fallback = Footer(showReloadConfig: true, showOpenConfig: true, showRevealConfig: true, showRelaunch: true, showQuit: true)
}

struct DebugSettings: Codable {
    var showWindow: Bool

    static let fallback = DebugSettings(showWindow: false)
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
            let defaultURL = Bundle.main.url(forResource: "DefaultConfig", withExtension: "json")
                ?? Bundle.module.url(forResource: "DefaultConfig", withExtension: "json")
            if let defaultURL,
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
