<p align="center">
  <img src="docs/assets/logo.svg" alt="ClipShield" width="96" />
</p>

# ClipShield

ClipShield is a macOS menu bar clipboard guardian that detects and redacts PII before it hits Slack, Jira, Notion, or any other app. It runs locally, stays configurable, and ships with a CLI for batch scanning and redaction.

## Why ClipShield

- Detects PAN/IBAN/SSN/email/phone with validation (Luhn + IBAN checksum)
- Custom regex rules per team needs
- One-click redact or tokenize from the menu bar
- Safe Paste mode auto-redacts on clipboard change
- Logs are local and **off by default**
- CLI for scan/redact/tokenize workflows

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools

## Build and Run

Build the binaries:

```bash
./scripts/build.sh
```

Run the menu bar app:

```bash
swift run ClipShield
```

Run the CLI:

```bash
swift run clipshield --help
```

## Configuration

ClipShield loads a JSON config from:

```
~/Library/Application Support/ClipShield/config.json
```

On first launch, the default config is copied into that path. Update it and use **Reload Config** from the menu bar.

Key settings you can tune:

- `monitoring.enabled` and `monitoring.safePaste`
- `detection.builtins` (pan/iban/ssn/email/phone)
- `detection.customRules` for regex-based rules
- `redaction.perType` and tokenization prefix/salt
- `logging.enabled` (off by default)

Example custom rule:

```json
{
  "id": "slack_token",
  "label": "Slack Token",
  "pattern": "\\bxox[baprs]-[0-9a-zA-Z-]{10,48}\\b",
  "enabled": true,
  "strategy": "tokenize"
}
```

## CLI Examples

Scan text:

```bash
echo "My SSN is 123-45-6789" | swift run clipshield scan --stdin
```

Redact a file:

```bash
swift run clipshield redact --file ./notes.txt --strategy mask
```

Tokenize and copy to clipboard:

```bash
swift run clipshield tokenize --text "4111 1111 1111 1111" --copy
```

## Packaging

Create an app bundle under `dist/`:

```bash
./scripts/package_app.sh 0.1.0
```

Create a release zip:

```bash
./scripts/release.sh 0.1.0
```

## Local-Only by Design

ClipShield never sends clipboard data to the network. All detection, redaction, and logging happen locally on your Mac.
