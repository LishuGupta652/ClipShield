# Configuration

ClipShield is config-driven. The config file lives at:

```
~/Library/Application Support/ClipShield/config.json
```

Reload the config from the menu bar after edits.

## Core Settings

- `monitoring.enabled`: enable/disable background monitoring
- `monitoring.pollIntervalSeconds`: how often to scan the clipboard
- `monitoring.safePaste.enabled`: auto-redact when PII is detected
- `monitoring.safePaste.notifyOnAutoRedact`: notify when Safe Paste changes the clipboard
- `monitoring.notifyOnDetect`: notify when PII is detected
- `detection.builtins`: toggle PAN/IBAN/SSN/email/phone detection
- `detection.customRules`: add regex-based rules
- `redaction.perType`: per-type redaction strategy
- `logging.enabled`: local logging (off by default)

## Custom Rule Example

```json
{
  "id": "slack_token",
  "label": "Slack Token",
  "pattern": "\\bxox[baprs]-[0-9a-zA-Z-]{10,48}\\b",
  "enabled": true,
  "strategy": "tokenize"
}
```

## Tokenization

Tokenization replaces matched values with deterministic tokens that never leave your machine. Configure:

- `redaction.tokenization.prefix`
- `redaction.tokenization.hashLength`
- `redaction.tokenization.salt`
