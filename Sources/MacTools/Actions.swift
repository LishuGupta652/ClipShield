import Cocoa

enum AppPaths {
    static let systemSettings = "/System/Applications/System Settings.app"
    static let calendar = "/System/Applications/Calendar.app"
    static let clock = "/System/Applications/Clock.app"
    static let screenshot = "/System/Applications/Utilities/Screenshot.app"
}

enum SystemSettingsPane {
    static let wifi = "com.apple.preference.network"
    static let bluetooth = "com.apple.preference.bluetooth"
    static let sound = "com.apple.preference.sound"
    static let focus = "com.apple.preference.focus"
    static let displays = "com.apple.preference.displays"
    static let keyboard = "com.apple.preference.keyboard"
    static let battery = "com.apple.preference.battery"
    static let dateTime = "com.apple.preference.datetime"
}

enum SystemSettings {
    static func open(paneID: String?) {
        if let paneID,
           let url = URL(string: "x-apple.systempreferences:\(paneID)"),
           NSWorkspace.shared.open(url) {
            return
        }
        let appURL = URL(fileURLWithPath: AppPaths.systemSettings)
        _ = NSWorkspace.shared.open(appURL)
    }
}

enum AppLauncher {
    static func openApp(at path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
}

enum ProcessRunner {
    static func run(_ launchPath: String, _ arguments: [String] = []) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        try? process.run()
    }
}

enum ScriptRunner {
    static func runAppleScript(_ script: String) {
        ProcessRunner.run("/usr/bin/osascript", ["-e", script])
    }
}

enum Relauncher {
    static func relaunch() {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
        NSApp.terminate(nil)
    }
}
