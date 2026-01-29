import Cocoa
import CoreWLAN
import IOKit.ps

final class StatusProvider {
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    func timeStatus() -> String {
        "Time: \(formatter.string(from: Date()))"
    }

    func batteryStatus() -> String {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return "Battery: Unavailable"
        }
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return "Battery: Unavailable"
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            guard let current = description[kIOPSCurrentCapacityKey as String] as? Int,
                  let max = description[kIOPSMaxCapacityKey as String] as? Int else {
                continue
            }

            let percentage = max > 0 ? Int((Double(current) / Double(max)) * 100.0) : 0
            let charging = (description[kIOPSIsChargingKey as String] as? Bool) ?? false
            let chargingLabel = charging ? " (charging)" : ""
            return "Battery: \(percentage)%\(chargingLabel)"
        }

        return "Battery: Unavailable"
    }

    func wifiStatus() -> String {
        guard let interface = CWWiFiClient.shared().interface() else {
            return "Wi-Fi: Unavailable"
        }
        if interface.powerOn() {
            if let ssid = interface.ssid(), !ssid.isEmpty {
                return "Wi-Fi: On (\(ssid))"
            }
            return "Wi-Fi: On"
        }
        return "Wi-Fi: Off"
    }

    func clipboardStatus() -> String {
        let pasteboard = NSPasteboard.general
        guard let contents = pasteboard.string(forType: .string), !contents.isEmpty else {
            return "Clipboard: (empty)"
        }
        let collapsed = contents.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let maxLength = 48
        let summary = collapsed.count > maxLength ? String(collapsed.prefix(maxLength)) + "..." : collapsed
        return "Clipboard: \(summary)"
    }

    func clearClipboard() {
        NSPasteboard.general.clearContents()
    }
}
