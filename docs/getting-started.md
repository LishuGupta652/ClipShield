# Getting Started

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools

## Build & Run

```bash
./scripts/build.sh
```

```bash
swift run ClipShield
```

A menu bar icon appears immediately.

## First Run

ClipShield copies a default config to:

```
~/Library/Application Support/ClipShield/config.json
```

Edit the JSON file and click **Reload Config** in the menu bar.

## Project Structure

```
mac-tools/
  Sources/ClipShieldCore/
  Sources/ClipShieldApp/
  Sources/ClipShieldCLI/
  Resources/
  scripts/
  Casks/
  docs/
```
