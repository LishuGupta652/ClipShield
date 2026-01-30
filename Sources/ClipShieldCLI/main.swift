import Foundation
import ClipShieldCore
import AppKit

@main
struct ClipShieldCLI {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        guard !args.isEmpty else {
            printHelp()
            return
        }

        if args.contains("--help") || args.contains("-h") {
            printHelp()
            return
        }

        let command = args[0]
        let parsed = ArgParser.parse(Array(args.dropFirst()))
        switch command {
        case "scan":
            runScan(parsed)
        case "redact":
            runRedact(parsed, strategyOverride: nil)
        case "tokenize":
            runRedact(parsed, strategyOverride: .tokenize)
        case "config":
            runConfig(parsed)
        case "rules":
            runRules(parsed)
        case "watch":
            runWatch(parsed)
        default:
            print("Unknown command: \(command)\n")
            printHelp()
        }
    }

    private static func runScan(_ parsed: ParsedArgs) {
        guard let input = resolveInput(parsed) else {
            print("No input provided. Use --text, --file, or --stdin.")
            return
        }

        let configManager = resolveConfigManager(parsed)
        let config = configManager.loadConfig()
        let detector = PIIDetector()
        let result = detector.detect(in: input, config: config)

        if parsed.flags.contains("json") {
            let output = ScanOutput.from(result)
            if let data = try? JSONEncoder().encode(output),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }
            return
        }

        print("Types: \(result.summary())")
        print("Matches: \(result.matches.count)")
    }

    private static func runRedact(_ parsed: ParsedArgs, strategyOverride: RedactionStrategy?) {
        guard let input = resolveInput(parsed) else {
            print("No input provided. Use --text, --file, or --stdin.")
            return
        }

        let configManager = resolveConfigManager(parsed)
        let config = configManager.loadConfig()
        let detector = PIIDetector()
        let redactor = Redactor()
        let detection = detector.detect(in: input, config: config)

        let strategy = strategyOverride ?? parsed.options["strategy"].flatMap { RedactionStrategy(rawValue: $0) } ?? config.redaction.defaultStrategy
        let mode: RedactionMode
        switch strategy {
        case .mask: mode = .mask
        case .tokenize: mode = .tokenize
        case .remove: mode = .remove
        }

        let output = redactor.redact(text: input, matches: detection.matches, mode: mode, config: config)

        if parsed.flags.contains("copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(output, forType: .string)
            print("Copied redacted text to clipboard.")
        } else {
            print(output)
        }
    }

    private static func runConfig(_ parsed: ParsedArgs) {
        guard let subcommand = parsed.positionals.first else {
            print("config requires a subcommand: path | init | print")
            return
        }

        let configManager = resolveConfigManager(parsed)
        switch subcommand {
        case "path":
            print(configManager.configFileURL().path)
        case "init":
            configManager.ensureUserConfig()
            print("Config initialized at \(configManager.configFileURL().path)")
        case "print":
            if let data = try? Data(contentsOf: configManager.configFileURL()),
               let text = String(data: data, encoding: .utf8) {
                print(text)
            }
        default:
            print("Unknown config subcommand: \(subcommand)")
        }
    }

    private static func runRules(_ parsed: ParsedArgs) {
        let rules = [
            ("pan", "Payment card numbers (Luhn validated)"),
            ("iban", "International Bank Account Numbers (IBAN)"),
            ("ssn", "US Social Security Numbers"),
            ("email", "Email addresses"),
            ("phone", "Phone numbers (10-15 digits)")
        ]
        if parsed.flags.contains("json") {
            let output = rules.map { RuleOutput(id: $0.0, description: $0.1) }
            if let data = try? JSONEncoder().encode(output),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }
            return
        }
        for rule in rules {
            print("- \(rule.0): \(rule.1)")
        }
    }

    private static func runWatch(_ parsed: ParsedArgs) {
        let interval = Double(parsed.options["interval"] ?? "1.0") ?? 1.0
        let configManager = resolveConfigManager(parsed)
        let config = configManager.loadConfig()
        let detector = PIIDetector()
        let monitor = ClipboardMonitorCLI()
        monitor.onTextChange = { text in
            let detection = detector.detect(in: text, config: config)
            if detection.matches.isEmpty {
                print("[\(DateFormatting.iso8601())] clean")
            } else {
                print("[\(DateFormatting.iso8601())] \(detection.summary())")
            }
        }
        monitor.start(interval: interval)
        RunLoop.current.run()
    }

    private static func resolveInput(_ parsed: ParsedArgs) -> String? {
        if let text = parsed.options["text"] {
            return text
        }
        if let file = parsed.options["file"] {
            return try? String(contentsOfFile: file, encoding: .utf8)
        }
        if parsed.flags.contains("stdin") {
            return readStdin()
        }
        return nil
    }

    private static func resolveConfigManager(_ parsed: ParsedArgs) -> ConfigManager {
        if let path = parsed.options["config"] {
            return ConfigManager(configURLOverride: URL(fileURLWithPath: path))
        }
        return ConfigManager.shared
    }

    private static func readStdin() -> String? {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private static func printHelp() {
        let help = """
ClipShield CLI

Usage:
  clipshield scan --text "..." | --file path | --stdin [--json]
  clipshield redact --text "..." [--strategy mask|tokenize|remove] [--copy]
  clipshield tokenize --text "..." [--copy]
  clipshield config path|init|print
  clipshield rules [--json]
  clipshield watch [--interval 1.0]

Options:
  --config PATH   Use a custom config file path or directory
  --stdin         Read input from stdin
  --text TEXT     Provide input text directly
  --file PATH     Read input from a file
  --json          Output JSON where supported
  --copy          Copy output to clipboard (redact/tokenize)
"""
        print(help)
    }
}

struct ParsedArgs {
    var flags: Set<String>
    var options: [String: String]
    var positionals: [String]
}

struct ArgParser {
    static func parse(_ args: [String]) -> ParsedArgs {
        var flags: Set<String> = []
        var options: [String: String] = [:]
        var positionals: [String] = []

        var index = 0
        while index < args.count {
            let arg = args[index]
            if arg.hasPrefix("--") {
                let trimmed = String(arg.dropFirst(2))
                if let eqIndex = trimmed.firstIndex(of: "=") {
                    let key = String(trimmed[..<eqIndex])
                    let value = String(trimmed[trimmed.index(after: eqIndex)...])
                    options[key] = value
                } else if index + 1 < args.count, !args[index + 1].hasPrefix("--") {
                    options[trimmed] = args[index + 1]
                    index += 1
                } else {
                    flags.insert(trimmed)
                }
            } else if arg.hasPrefix("-") {
                let key = String(arg.dropFirst(1))
                flags.insert(key)
            } else {
                positionals.append(arg)
            }
            index += 1
        }

        return ParsedArgs(flags: flags, options: options, positionals: positionals)
    }
}

struct ScanOutput: Codable {
    let types: [String]
    let matches: Int

    static func from(_ result: DetectionResult) -> ScanOutput {
        let types = result.countsByType.map { "\($0.key.rawValue):\($0.value)" }
        return ScanOutput(types: types, matches: result.matches.count)
    }
}

struct RuleOutput: Codable {
    let id: String
    let description: String
}

final class ClipboardMonitorCLI {
    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int

    var onTextChange: ((String) -> Void)?

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func start(interval: Double) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        onTextChange?(text)
    }
}
