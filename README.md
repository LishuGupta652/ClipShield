![MacTools](docs/assets/logo.svg)

# MacTools (Menu Bar Boilerplate)

MacTools is a complete, minimal macOS menu bar app scaffold you can customize into your personal "Mac tools" suite. It ships with:

- A working menu bar app (AppKit)
- Dynamic status items (time, battery, Wi-Fi, clipboard)
- Quick actions for common system settings and utilities
- A JSON config file for customization (menu sections, actions, icon)
- Build, package, and release scripts
- A Homebrew Cask template

> This repo is a boilerplate. The menu items are intentionally simple and safe (no private APIs). You can expand or replace them as needed.

## Menu Preview

![MacTools menu preview](docs/Menu_Preview.png)

---

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools

---

## Menu Bar Checklist (Reference)

### Appearance & Layout

- Menu bar visible at top of screen
- Auto-hide turned on/off as desired (System Settings -> Desktop & Dock)
- Icons not overcrowded

### Useful Controls Added

- Wi-Fi icon enabled
- Battery percentage showing
- Sound/Volume control available
- Bluetooth toggle accessible
- Time & Date format correct
- Spotlight search working

### Control Center Setup

- Control Center icons added to menu bar
- Focus / Do Not Disturb available
- Screen brightness and keyboard brightness accessible

### Productivity Tools

- Calendar or clock widget pinned
- Screenshot / screen recording shortcut available
- Clipboard manager (optional) installed

### Troubleshooting

- Toolbar not frozen or missing
- Apps showing correct menu options
- Restart Finder if icons disappear

---

## Project Structure

```
mac-tools/
  Package.swift
  Sources/MacTools/
    MacToolsApp.swift
    StatusProvider.swift
    Actions.swift
  Resources/
    Info.plist
  scripts/
    build.sh
    package_app.sh
    release.sh
    sign_notarize.sh
  Casks/
    mactools.rb
```

---

## Build and Run (Local)

Build the executable:

```bash
./scripts/build.sh
```

Run from source (menu bar item appears):

```bash
swift run
```

## Documentation Site

Docs live in `docs/` and are rendered with Docsify (no build step).

Preview locally:

```bash
cd docs
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

Docs site: `https://macos-toolkit.lishugupta.in`

If you prefer Docsify's dev server:

```bash
npx docsify-cli serve docs
```

---

## Package a .app

Create an app bundle under `dist/`:

```bash
./scripts/package_app.sh 1.0.0
```

Optional environment overrides:

```bash
BUNDLE_ID=com.yourname.mactools ./scripts/package_app.sh 1.0.0
```

---

## Create a Release ZIP + SHA

```bash
./scripts/release.sh 1.0.0
```

This creates:

```
dist/MacTools-1.0.0.zip
```

And prints the SHA-256 you will paste into the cask.

---

## Signing and Notarization (Recommended)

Gatekeeper will warn on unsigned apps. Use the helper script:

```bash
./scripts/sign_notarize.sh dist/MacTools.app "Developer ID Application: Your Name" you@example.com TEAMID APP_SPECIFIC_PASSWORD
```

> You can also notarize the ZIP instead of the .app if you prefer. Adjust the script accordingly.

---

## Customize the App (Config-first)

MacTools loads a JSON config from:

```
~/Library/Application Support/MacTools/config.json
```

The first launch copies a default config from the app bundle (source file: `Sources/MacTools/Resources/DefaultConfig.json`). Edit this file and choose **Reload Config** from the menu.
The config is strict JSON (no comments).

### Example Config Snippet

```json
{
  "appTitle": "MacTools",
  "menuBarIcon": { "symbolName": "sparkles", "accessibilityLabel": "MacTools" },
  "sections": [
    {
      "title": "Quick Actions",
      "items": [
        { "type": "openSettings", "title": "Wi-Fi Settings...", "paneID": "com.apple.preference.network" },
        { "type": "openURL", "title": "Open Docs", "url": "https://example.com" },
        { "type": "shell", "title": "Say Hi", "command": "/usr/bin/say", "arguments": ["Hi"] }
      ]
    }
  ]
}
```

### Supported Action Types

Other top-level config keys:

- `appTitle` (menu header and tooltip)
- `menuBarIcon` (SF Symbol name or custom icon path)
- `statusSection` (toggle dynamic status items)
- `debug` (show a debug window on launch)

- `openSettings` (paneID)
- `openApp` (path)
- `openURL` (url)
- `shell` (command, arguments)
- `appleScript` (script)
- `clipboardCopy` (text)
- `clipboardClear`
- `reloadConfig`
- `openConfig`
- `revealConfig`
- `relaunch`
- `quit`
- `separator`

### Custom Menu Bar Icon

You can choose either:

- **SF Symbol** via `menuBarIcon.symbolName`, or
- **Custom file** via `menuBarIcon.iconPath` (relative to your config file directory)

Tip: menu bar icons look best as template (monochrome) PNGs.

Example for a custom file:

```json
{
  "menuBarIcon": {
    "iconPath": "MenuBarIcon.png",
    "accessibilityLabel": "MacTools"
  }
}
```

### App Icon (Dock / Finder)

If you want a custom app icon for the `.app` bundle, add:

```
Resources/AppIcon.icns
```

Then re-run `./scripts/package_app.sh`.

### Advanced: Code-level Customization

If you want deeper behavior changes, edit:

- `Sources/MacTools/MacToolsApp.swift` (menu building, actions)
- `Sources/MacTools/StatusProvider.swift` (dynamic status logic)

### Update System Settings Links

System Settings pane IDs can change across macOS versions. Update them in:

- `Sources/MacTools/Actions.swift`

If a deep link fails, the app falls back to opening System Settings.

### Update Status Items

Dynamic status logic lives in:

- `Sources/MacTools/StatusProvider.swift`

---

## Homebrew Cask Publishing

### 1) Host the Release ZIP

Upload `dist/MacTools-1.0.0.zip` to a stable HTTPS URL (e.g., GitHub Releases).

### 2) Update the Cask Template

Edit `Casks/mactools.rb`:

- `version`
- `sha256`
- `url`
- `homepage`

### 3) Install via a Personal Tap

1. Create a repo named `homebrew-tap` (or similar).
2. Add your cask file at:

```
Casks/mactools.rb
```

3. Install:

```bash
brew tap yourname/tap
brew install --cask mactools
```

### 4) Submit to Homebrew/homebrew-cask (Optional)

For public distribution:

1. Fork `Homebrew/homebrew-cask`
2. Add `Casks/mactools.rb`
3. Open a PR

---

## Troubleshooting

- If the menu bar item does not appear, run the app once from Terminal and check for logs
- If Spotlight trigger fails, grant Accessibility permission to MacTools
- If icons disappear, run `killall Finder`

---

## Notes

- This app intentionally avoids private APIs.
- Some actions may require user permissions (Accessibility, Automation).
- You can replace the menu bar icon by adding `Resources/AppIcon.icns`.
