import Foundation

public final class EventLogger {
    private let config: LoggingConfig
    private let fileURL: URL
    private let queue = DispatchQueue(label: "clipshield.logger")

    public init(config: LoggingConfig, fileURL: URL) {
        self.config = config
        self.fileURL = fileURL
    }

    public func log(event: String, metadata: [String: String] = [:]) {
        guard config.enabled else { return }
        let timestamp = DateFormatting.iso8601()
        var payload = "\(timestamp) \(event)"
        if !metadata.isEmpty {
            let pairs = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            payload += " \(pairs)"
        }
        payload += "\n"
        queue.async {
            if let data = payload.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.fileURL.path) {
                    if let handle = try? FileHandle(forWritingTo: self.fileURL) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        try? handle.close()
                    }
                } else {
                    try? data.write(to: self.fileURL, options: [.atomic])
                }
            }
        }
    }
}
