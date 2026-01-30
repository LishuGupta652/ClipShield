import Foundation

public enum RedactionMode {
    case auto
    case mask
    case tokenize
    case remove
}

public final class Redactor {
    public init() {}

    public func redact(text: String, matches: [DetectionMatch], mode: RedactionMode, config: AppConfig) -> String {
        guard !matches.isEmpty else { return text }

        let replacements = matches.map { match -> Replacement in
            let strategy = resolveStrategy(for: match, mode: mode, config: config)
            let replacement = replacementText(for: match, strategy: strategy, config: config)
            return Replacement(range: match.range, value: replacement)
        }

        return apply(replacements: replacements, to: text)
    }

    public func token(for value: String, type: PIIType, config: TokenizationConfig) -> String {
        let normalized = normalize(value: value, for: type)
        let hash = Hashing.sha256Hex(config.salt + normalized)
        let trimmed = String(hash.prefix(max(4, config.hashLength)))
        return "\(config.prefix)\(type.rawValue)_\(trimmed)"
    }

    private func resolveStrategy(for match: DetectionMatch, mode: RedactionMode, config: AppConfig) -> RedactionStrategy {
        switch mode {
        case .mask: return .mask
        case .tokenize: return .tokenize
        case .remove: return .remove
        case .auto:
            if let override = config.redaction.override(for: match.type) {
                return override.strategy
            }
            return config.redaction.defaultStrategy
        }
    }

    private func replacementText(for match: DetectionMatch, strategy: RedactionStrategy, config: AppConfig) -> String {
        switch strategy {
        case .mask:
            return mask(value: match.value, type: match.type, config: config, custom: match.ruleID)
        case .tokenize:
            return token(for: match.value, type: match.type, config: config.redaction.tokenization)
        case .remove:
            return "[REDACTED:\(match.type.displayName.uppercased())]"
        }
    }

    private func mask(value: String, type: PIIType, config: AppConfig, custom: String?) -> String {
        let override = config.redaction.override(for: type)
        let maskCharacter = override?.maskCharacter?.first ?? config.redaction.maskCharacter.first ?? "*"
        let preserveLast = override?.preserveLastDigits ?? config.redaction.preserveLastDigits

        switch type {
        case .pan:
            return maskDigitsPreservingSeparators(value, maskCharacter: maskCharacter, preserveLast: preserveLast)
        case .ssn:
            return maskDigitsPreservingSeparators(value, maskCharacter: maskCharacter, preserveLast: preserveLast)
        case .phone:
            return maskDigitsPreservingSeparators(value, maskCharacter: maskCharacter, preserveLast: preserveLast)
        case .iban:
            return maskIban(value, maskCharacter: maskCharacter, preserveLast: preserveLast)
        case .email:
            return maskEmail(value, maskCharacter: maskCharacter)
        case .custom:
            return maskAlphanumericsPreservingSeparators(value, maskCharacter: maskCharacter, preserveLast: preserveLast)
        }
    }

    private func maskDigitsPreservingSeparators(_ value: String, maskCharacter: Character, preserveLast: Int) -> String {
        let digits = value.digitsOnly()
        guard !digits.isEmpty else { return value }
        let preserve = max(0, preserveLast)
        let keepStartIndex = max(0, digits.count - preserve)
        var digitIndex = 0
        var output = ""
        for ch in value {
            if ch.isNumber {
                if digitIndex < keepStartIndex {
                    output.append(maskCharacter)
                } else {
                    output.append(ch)
                }
                digitIndex += 1
            } else {
                output.append(ch)
            }
        }
        return output
    }

    private func maskAlphanumericsPreservingSeparators(_ value: String, maskCharacter: Character, preserveLast: Int) -> String {
        let lettersAndDigits = value.filter { $0.isLetter || $0.isNumber }
        guard !lettersAndDigits.isEmpty else { return value }
        let preserve = max(0, preserveLast)
        let keepStartIndex = max(0, lettersAndDigits.count - preserve)
        var tokenIndex = 0
        var output = ""
        for ch in value {
            if ch.isLetter || ch.isNumber {
                if tokenIndex < keepStartIndex {
                    output.append(maskCharacter)
                } else {
                    output.append(ch)
                }
                tokenIndex += 1
            } else {
                output.append(ch)
            }
        }
        return output
    }

    private func maskIban(_ value: String, maskCharacter: Character, preserveLast: Int) -> String {
        let stripped = value.replacingOccurrences(of: " ", with: "")
        guard stripped.count >= 8 else { return value }
        let upper = stripped.uppercased()
        let prefix = upper.prefix(4)
        let suffix = upper.suffix(preserveLast)
        let maskedCount = max(0, upper.count - prefix.count - suffix.count)
        let masked = String(repeating: String(maskCharacter), count: maskedCount)
        let combined = prefix + masked + suffix
        var output = ""
        var index = combined.startIndex
        for ch in value {
            if ch == " " {
                output.append(" ")
            } else if index < combined.endIndex {
                output.append(combined[index])
                index = combined.index(after: index)
            }
        }
        return output
    }

    private func maskEmail(_ value: String, maskCharacter: Character) -> String {
        let parts = value.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return value }
        let local = String(parts[0])
        let domain = String(parts[1])
        if local.count <= 2 {
            return String(repeating: String(maskCharacter), count: max(1, local.count)) + "@" + domain
        }
        let first = local.prefix(1)
        let last = local.suffix(1)
        let masked = String(repeating: String(maskCharacter), count: max(1, local.count - 2))
        return "\(first)\(masked)\(last)@\(domain)"
    }

    private func normalize(value: String, for type: PIIType) -> String {
        switch type {
        case .pan, .phone, .ssn:
            return value.digitsOnly()
        case .iban:
            return value.replacingOccurrences(of: " ", with: "").uppercased()
        case .email:
            return value.trimmed().lowercased()
        case .custom:
            return value.trimmed()
        }
    }

    private func apply(replacements: [Replacement], to text: String) -> String {
        let sorted = replacements.sorted { $0.range.location > $1.range.location }
        var result = text as NSString
        for replacement in sorted {
            result = result.replacingCharacters(in: replacement.range, with: replacement.value) as NSString
        }
        return result as String
    }
}

private struct Replacement {
    let range: NSRange
    let value: String
}
