# Redaction & Rules

ClipShield ships with strong default rules:

- **PAN (payment cards)**: 13–19 digits + Luhn validation
- **IBAN**: country code + checksum validation (mod 97)
- **SSN**: excludes invalid ranges (000/666/9xx)
- **Email**: RFC-style pattern
- **Phone**: 10–15 digits with separators

## Redaction Strategies

- `mask`: hides sensitive characters, preserves last digits
- `tokenize`: replaces with a stable token (hash-based)
- `remove`: replaces with `[REDACTED:TYPE]`

You can set the default strategy in `redaction.defaultStrategy` and override per type in `redaction.perType`.

## Safe Paste Mode

When Safe Paste is enabled, any detected PII is automatically redacted (or tokenized) before you paste. This makes pasting into chat or ticketing tools safer by default.
