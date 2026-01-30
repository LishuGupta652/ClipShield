import Foundation
import AppKit

public enum RedactionStrategy: String, Codable {
    case mask
    case tokenize
    case remove
}

public struct AppConfig: Codable {
    public var version: Int
    public var appTitle: String
    public var menuBarIcon: MenuBarIcon
    public var monitoring: MonitoringConfig
    public var detection: DetectionConfig
    public var redaction: RedactionConfig
    public var logging: LoggingConfig
    public var debug: DebugSettings

    public init(
        version: Int,
        appTitle: String,
        menuBarIcon: MenuBarIcon,
        monitoring: MonitoringConfig,
        detection: DetectionConfig,
        redaction: RedactionConfig,
        logging: LoggingConfig,
        debug: DebugSettings
    ) {
        self.version = version
        self.appTitle = appTitle
        self.menuBarIcon = menuBarIcon
        self.monitoring = monitoring
        self.detection = detection
        self.redaction = redaction
        self.logging = logging
        self.debug = debug
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        appTitle = try container.decodeIfPresent(String.self, forKey: .appTitle) ?? "ClipShield"
        menuBarIcon = try container.decodeIfPresent(MenuBarIcon.self, forKey: .menuBarIcon) ?? .fallback
        monitoring = try container.decodeIfPresent(MonitoringConfig.self, forKey: .monitoring) ?? .fallback
        detection = try container.decodeIfPresent(DetectionConfig.self, forKey: .detection) ?? .fallback
        redaction = try container.decodeIfPresent(RedactionConfig.self, forKey: .redaction) ?? .fallback
        logging = try container.decodeIfPresent(LoggingConfig.self, forKey: .logging) ?? .fallback
        debug = try container.decodeIfPresent(DebugSettings.self, forKey: .debug) ?? .fallback
    }

    public static let fallback: AppConfig = {
        AppConfig(
            version: 1,
            appTitle: "ClipShield",
            menuBarIcon: .fallback,
            monitoring: .fallback,
            detection: .fallback,
            redaction: .fallback,
            logging: .fallback,
            debug: .fallback
        )
    }()
}

public struct MenuBarIcon: Codable {
    public var symbolName: String?
    public var alertSymbolName: String?
    public var iconPath: String?
    public var accessibilityLabel: String?

    public static let fallback = MenuBarIcon(
        symbolName: "shield.lefthalf.filled",
        alertSymbolName: "exclamationmark.triangle.fill",
        iconPath: nil,
        accessibilityLabel: "ClipShield"
    )
}

public struct MonitoringConfig: Codable {
    public var enabled: Bool
    public var pollIntervalSeconds: Double
    public var maxScanLength: Int
    public var safePaste: SafePasteConfig
    public var notifyOnDetect: Bool

    public static let fallback = MonitoringConfig(
        enabled: true,
        pollIntervalSeconds: 0.75,
        maxScanLength: 50_000,
        safePaste: .fallback,
        notifyOnDetect: false
    )
}

public struct SafePasteConfig: Codable {
    public var enabled: Bool
    public var action: RedactionStrategy
    public var notifyOnAutoRedact: Bool

    public static let fallback = SafePasteConfig(
        enabled: false,
        action: .mask,
        notifyOnAutoRedact: true
    )
}

public struct DetectionConfig: Codable {
    public var builtins: [String: RuleToggle]
    public var customRules: [CustomRule]

    public static let defaultBuiltins: [String: RuleToggle] = [
        "pan": RuleToggle(enabled: true),
        "iban": RuleToggle(enabled: true),
        "ssn": RuleToggle(enabled: true),
        "email": RuleToggle(enabled: true),
        "phone": RuleToggle(enabled: true)
    ]

    public init(builtins: [String: RuleToggle], customRules: [CustomRule]) {
        self.builtins = builtins
        self.customRules = customRules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedBuiltins = try container.decodeIfPresent([String: RuleToggle].self, forKey: .builtins) ?? [:]
        builtins = DetectionConfig.defaultBuiltins.merging(decodedBuiltins) { _, new in new }
        customRules = try container.decodeIfPresent([CustomRule].self, forKey: .customRules) ?? []
    }

    public static let fallback = DetectionConfig(builtins: DetectionConfig.defaultBuiltins, customRules: [])

    public func isEnabled(_ type: PIIType) -> Bool {
        builtins[type.rawValue]?.enabled ?? true
    }
}

public struct RuleToggle: Codable {
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
}

public struct CustomRule: Codable {
    public var id: String
    public var label: String
    public var pattern: String
    public var enabled: Bool
    public var strategy: RedactionStrategy?
    public var preserveLastDigits: Int?
    public var maskCharacter: String?
    public var caseInsensitive: Bool

    public init(
        id: String,
        label: String,
        pattern: String,
        enabled: Bool = true,
        strategy: RedactionStrategy? = nil,
        preserveLastDigits: Int? = nil,
        maskCharacter: String? = nil,
        caseInsensitive: Bool = true
    ) {
        self.id = id
        self.label = label
        self.pattern = pattern
        self.enabled = enabled
        self.strategy = strategy
        self.preserveLastDigits = preserveLastDigits
        self.maskCharacter = maskCharacter
        self.caseInsensitive = caseInsensitive
    }
}

public struct RedactionConfig: Codable {
    public var defaultStrategy: RedactionStrategy
    public var maskCharacter: String
    public var preserveLastDigits: Int
    public var perType: [String: RedactionOverride]
    public var tokenization: TokenizationConfig

    public init(
        defaultStrategy: RedactionStrategy,
        maskCharacter: String,
        preserveLastDigits: Int,
        perType: [String: RedactionOverride],
        tokenization: TokenizationConfig
    ) {
        self.defaultStrategy = defaultStrategy
        self.maskCharacter = maskCharacter
        self.preserveLastDigits = preserveLastDigits
        self.perType = perType
        self.tokenization = tokenization
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultStrategy = try container.decodeIfPresent(RedactionStrategy.self, forKey: .defaultStrategy) ?? .mask
        maskCharacter = try container.decodeIfPresent(String.self, forKey: .maskCharacter) ?? "*"
        preserveLastDigits = try container.decodeIfPresent(Int.self, forKey: .preserveLastDigits) ?? 4
        let decodedOverrides = try container.decodeIfPresent([String: RedactionOverride].self, forKey: .perType) ?? [:]
        perType = RedactionConfig.defaultOverrides.merging(decodedOverrides) { _, new in new }
        tokenization = try container.decodeIfPresent(TokenizationConfig.self, forKey: .tokenization) ?? .fallback
    }

    public static let defaultOverrides: [String: RedactionOverride] = [
        "pan": RedactionOverride(strategy: .mask, preserveLastDigits: 4, maskCharacter: nil),
        "iban": RedactionOverride(strategy: .mask, preserveLastDigits: 4, maskCharacter: nil),
        "ssn": RedactionOverride(strategy: .mask, preserveLastDigits: 4, maskCharacter: nil),
        "email": RedactionOverride(strategy: .mask, preserveLastDigits: nil, maskCharacter: nil),
        "phone": RedactionOverride(strategy: .mask, preserveLastDigits: 2, maskCharacter: nil)
    ]

    public static let fallback = RedactionConfig(
        defaultStrategy: .mask,
        maskCharacter: "*",
        preserveLastDigits: 4,
        perType: RedactionConfig.defaultOverrides,
        tokenization: .fallback
    )

    public func override(for type: PIIType) -> RedactionOverride? {
        perType[type.rawValue]
    }
}

public struct RedactionOverride: Codable {
    public var strategy: RedactionStrategy
    public var preserveLastDigits: Int?
    public var maskCharacter: String?

    public init(strategy: RedactionStrategy, preserveLastDigits: Int? = nil, maskCharacter: String? = nil) {
        self.strategy = strategy
        self.preserveLastDigits = preserveLastDigits
        self.maskCharacter = maskCharacter
    }
}

public struct TokenizationConfig: Codable {
    public var prefix: String
    public var hashLength: Int
    public var salt: String

    public static let fallback = TokenizationConfig(prefix: "tok_", hashLength: 10, salt: "")
}

public struct LoggingConfig: Codable {
    public var enabled: Bool
    public var fileName: String

    public static let fallback = LoggingConfig(enabled: false, fileName: "clipshield.log")
}

public struct DebugSettings: Codable {
    public var showWindow: Bool

    public static let fallback = DebugSettings(showWindow: false)
}

public final class ConfigManager {
    public static let shared = ConfigManager()

    private let fileManager = FileManager.default
    private let appSupportURL: URL
    private let configURL: URL
    private let logsURL: URL

    public init(configURLOverride: URL? = nil) {
        let override = ConfigManager.resolveOverrideURL(explicit: configURLOverride)
        if let override {
            let normalized = ConfigManager.normalizeConfigURL(override)
            configURL = normalized
            appSupportURL = normalized.deletingLastPathComponent()
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
            appSupportURL = base.appendingPathComponent("ClipShield", isDirectory: true)
            configURL = appSupportURL.appendingPathComponent("config.json")
        }
        logsURL = appSupportURL.appendingPathComponent("Logs", isDirectory: true)
    }

    private static func resolveOverrideURL(explicit: URL?) -> URL? {
        if let explicit { return explicit }
        if let envPath = ProcessInfo.processInfo.environment["CLIPSHIELD_CONFIG"], !envPath.isEmpty {
            return URL(fileURLWithPath: envPath)
        }
        return nil
    }

    private static func normalizeConfigURL(_ url: URL) -> URL {
        if url.hasDirectoryPath {
            return url.appendingPathComponent("config.json")
        }
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return url.appendingPathComponent("config.json")
        }
        return url
    }

    public func ensureUserConfig() {
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: configURL.path) {
            if let data = defaultConfigData() {
                try? data.write(to: configURL, options: [.atomic])
            } else if let data = try? JSONEncoder().encode(AppConfig.fallback) {
                try? data.write(to: configURL, options: [.atomic])
            }
        }
    }

    public func loadConfig() -> AppConfig {
        ensureUserConfig()

        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(AppConfig.self, from: data) {
            return config
        }

        if let data = try? JSONEncoder().encode(AppConfig.fallback) {
            try? data.write(to: configURL, options: [.atomic])
        }

        return AppConfig.fallback
    }

    public func saveConfig(_ config: AppConfig) {
        ensureUserConfig()
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: configURL, options: [.atomic])
        }
    }

    public func configFileURL() -> URL {
        ensureUserConfig()
        return configURL
    }

    public func configDirectory() -> URL {
        appSupportURL
    }

    public func logsDirectory() -> URL {
        if !fileManager.fileExists(atPath: logsURL.path) {
            try? fileManager.createDirectory(at: logsURL, withIntermediateDirectories: true)
        }
        return logsURL
    }

    public func logFileURL(fileName: String?) -> URL {
        let name = (fileName?.isEmpty == false) ? fileName! : LoggingConfig.fallback.fileName
        return logsDirectory().appendingPathComponent(name)
    }

    public func openConfig() {
        let url = configFileURL()
        NSWorkspace.shared.open(url)
    }

    public func revealConfigInFinder() {
        let url = configFileURL()
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public func openLogFile(fileName: String?) {
        let url = logFileURL(fileName: fileName)
        if fileManager.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)
        }
    }

    private func defaultConfigData() -> Data? {
        let defaultURL = Bundle.module.url(forResource: "DefaultConfig", withExtension: "json")
            ?? Bundle.main.url(forResource: "DefaultConfig", withExtension: "json")
        guard let defaultURL else { return nil }
        return try? Data(contentsOf: defaultURL)
    }
}
