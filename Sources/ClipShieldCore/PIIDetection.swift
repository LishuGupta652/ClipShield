import Foundation

public enum PIIType: String, Codable, CaseIterable {
    case pan
    case iban
    case ssn
    case email
    case phone
    case custom

    public var displayName: String {
        switch self {
        case .pan: return "Payment Card"
        case .iban: return "IBAN"
        case .ssn: return "SSN"
        case .email: return "Email"
        case .phone: return "Phone"
        case .custom: return "Custom"
        }
    }
}

public struct DetectionMatch: Hashable {
    public let type: PIIType
    public let range: NSRange
    public let value: String
    public let ruleID: String?
    public let ruleLabel: String?

    public init(type: PIIType, range: NSRange, value: String, ruleID: String? = nil, ruleLabel: String? = nil) {
        self.type = type
        self.range = range
        self.value = value
        self.ruleID = ruleID
        self.ruleLabel = ruleLabel
    }
}

public struct DetectionResult {
    public let matches: [DetectionMatch]
    public let textLength: Int

    public init(matches: [DetectionMatch], textLength: Int) {
        self.matches = matches
        self.textLength = textLength
    }

    public var isEmpty: Bool {
        matches.isEmpty
    }

    public var types: [PIIType] {
        Array(Set(matches.map { $0.type }))
    }

    public var countsByType: [PIIType: Int] {
        var counts: [PIIType: Int] = [:]
        for match in matches {
            counts[match.type, default: 0] += 1
        }
        return counts
    }

    public func summary() -> String {
        if matches.isEmpty {
            return "None"
        }
        let ordered = countsByType.sorted { $0.key.rawValue < $1.key.rawValue }
        return ordered.map { "\($0.key.displayName): \($0.value)" }.joined(separator: ", ")
    }
}

public final class PIIDetector {
    private let panRegex = try! NSRegularExpression(pattern: "\\b(?:\\d[ -]*?){13,19}\\b", options: [])
    private let ibanRegex = try! NSRegularExpression(pattern: "\\b[A-Z]{2}[0-9]{2}[A-Z0-9 ]{11,30}\\b", options: [.caseInsensitive])
    private let ssnRegex = try! NSRegularExpression(pattern: "\\b(?!000|666|9\\d\\d)\\d{3}[- ]?(?!00)\\d{2}[- ]?(?!0000)\\d{4}\\b", options: [])
    private let emailRegex = try! NSRegularExpression(pattern: "\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b", options: [.caseInsensitive])
    private let phoneRegex = try! NSRegularExpression(pattern: "(?<![A-Z0-9])(?:\\+?\\d[\\d\\s().-]{7,}\\d)(?![A-Z0-9])", options: [.caseInsensitive])

    public init() {}

    public func detect(in text: String, config: AppConfig) -> DetectionResult {
        guard !text.isEmpty else {
            return DetectionResult(matches: [], textLength: 0)
        }

        let limitedText: String
        if config.monitoring.maxScanLength > 0, text.count > config.monitoring.maxScanLength {
            let prefix = text.prefix(config.monitoring.maxScanLength)
            limitedText = String(prefix)
        } else {
            limitedText = text
        }

        let nsText = limitedText as NSString
        var matches: [DetectionMatch] = []

        if config.detection.isEnabled(.pan) {
            matches.append(contentsOf: findMatches(regex: panRegex, in: nsText, type: .pan, validator: { value in
                let digits = value.digitsOnly()
                guard digits.count >= 13 && digits.count <= 19 else { return false }
                guard Set(digits).count > 1 else { return false }
                return self.luhnCheck(digits)
            }))
        }

        if config.detection.isEnabled(.iban) {
            matches.append(contentsOf: findMatches(regex: ibanRegex, in: nsText, type: .iban, validator: { value in
                let normalized = value.replacingOccurrences(of: " ", with: "")
                return self.ibanIsValid(normalized)
            }))
        }

        if config.detection.isEnabled(.ssn) {
            matches.append(contentsOf: findMatches(regex: ssnRegex, in: nsText, type: .ssn, validator: nil))
        }

        if config.detection.isEnabled(.email) {
            matches.append(contentsOf: findMatches(regex: emailRegex, in: nsText, type: .email, validator: nil))
        }

        if config.detection.isEnabled(.phone) {
            matches.append(contentsOf: findMatches(regex: phoneRegex, in: nsText, type: .phone, validator: { value in
                let digits = value.digitsOnly()
                guard digits.count >= 10 && digits.count <= 15 else { return false }
                guard Set(digits).count > 1 else { return false }
                return true
            }))
        }

        for rule in config.detection.customRules where rule.enabled {
            let options: NSRegularExpression.Options = rule.caseInsensitive ? [.caseInsensitive] : []
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: options) {
                matches.append(contentsOf: findMatches(regex: regex, in: nsText, type: .custom, validator: nil, ruleID: rule.id, ruleLabel: rule.label))
            }
        }

        let filtered = filterOverlappingMatches(matches)
        return DetectionResult(matches: filtered, textLength: limitedText.count)
    }

    private func findMatches(
        regex: NSRegularExpression,
        in text: NSString,
        type: PIIType,
        validator: ((String) -> Bool)?,
        ruleID: String? = nil,
        ruleLabel: String? = nil
    ) -> [DetectionMatch] {
        let range = NSRange(location: 0, length: text.length)
        let results = regex.matches(in: text as String, options: [], range: range)
        var matches: [DetectionMatch] = []
        for result in results {
            let value = text.substring(with: result.range)
            if let validator, !validator(value) {
                continue
            }
            matches.append(DetectionMatch(type: type, range: result.range, value: value, ruleID: ruleID, ruleLabel: ruleLabel))
        }
        return matches
    }

    private func filterOverlappingMatches(_ matches: [DetectionMatch]) -> [DetectionMatch] {
        let sorted = matches.sorted {
            if $0.range.length == $1.range.length {
                return $0.range.location < $1.range.location
            }
            return $0.range.length > $1.range.length
        }
        var kept: [DetectionMatch] = []
        for match in sorted {
            if kept.contains(where: { NSIntersectionRange($0.range, match.range).length > 0 }) {
                continue
            }
            kept.append(match)
        }
        return kept.sorted { $0.range.location < $1.range.location }
    }

    private func luhnCheck(_ digits: String) -> Bool {
        var sum = 0
        let reversed = digits.reversed().map { Int(String($0)) ?? 0 }
        for (index, digit) in reversed.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }

    private func ibanIsValid(_ iban: String) -> Bool {
        let trimmed = iban.replacingOccurrences(of: " ", with: "").uppercased()
        guard trimmed.count >= 15 && trimmed.count <= 34 else { return false }
        let rearranged = trimmed.dropFirst(4) + trimmed.prefix(4)
        var numeric = ""
        numeric.reserveCapacity(rearranged.count * 2)
        for ch in rearranged {
            if let value = ch.wholeNumberValue {
                numeric.append(String(value))
            } else if let scalar = ch.unicodeScalars.first {
                let converted = Int(scalar.value) - 55
                guard converted >= 10 && converted <= 35 else { return false }
                numeric.append(String(converted))
            } else {
                return false
            }
        }
        var remainder = 0
        for ch in numeric {
            guard let digit = ch.wholeNumberValue else { return false }
            remainder = (remainder * 10 + digit) % 97
        }
        return remainder == 1
    }
}
