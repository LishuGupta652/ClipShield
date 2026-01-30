import AppKit

enum ClipboardService {
    static func readText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    static func writeText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    static func clear() {
        NSPasteboard.general.clearContents()
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
