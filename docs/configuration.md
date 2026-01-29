# Configuration

MacTools is config-first. The menu is generated from JSON.

Config file location:

```
~/Library/Application Support/MacTools/config.json
```

Default template:

```
Sources/MacTools/Resources/DefaultConfig.json
```

## Top-Level Keys

- `version` (int)
- `appTitle` (string)
- `menuBarIcon` (object)
- `statusSection` (object)
- `sections` (array)
- `footer` (object)
- `debug` (object)

## Example

```json
{
  "version": 1,
  "appTitle": "MacTools",
  "menuBarIcon": {
    "symbolName": "hammer.circle.fill",
    "accessibilityLabel": "MacTools"
  },
  "statusSection": {
    "title": "Status",
    "showTime": true,
    "showBattery": true,
    "showWiFi": true,
    "showClipboard": true,
    "timeFormat": "EEE, MMM d h:mm a"
  },
  "sections": [
    {
      "title": "Quick Actions",
      "items": [
        { "type": "openSettings", "title": "Wi-Fi Settings...", "paneID": "com.apple.preference.network" },
        { "type": "openURL", "title": "Open Docs", "url": "https://example.com" },
        { "type": "shell", "title": "Say Hi", "command": "/usr/bin/say", "arguments": ["Hi"] }
      ]
    }
  ],
  "footer": {
    "showReloadConfig": true,
    "showOpenConfig": true,
    "showRevealConfig": true,
    "showRelaunch": true,
    "showQuit": true
  },
  "debug": {
    "showWindow": false
  }
}
```

## Menu Bar Icon

You can use either:

- `symbolName` for SF Symbols
- `iconPath` for a custom icon file (relative to the config directory)

Example:

```json
"menuBarIcon": {
  "iconPath": "MenuBarIcon.png",
  "accessibilityLabel": "My Tools"
}
```

## Time Format

`statusSection.timeFormat` uses standard `DateFormatter` patterns.

Example:

```json
"timeFormat": "HH:mm"
```

## Debug Window

To show a debug window on launch:

```json
"debug": { "showWindow": true }
```

You can also force it on via environment variable:

```bash
MACTOOLS_DEBUG=1 swift run
```
