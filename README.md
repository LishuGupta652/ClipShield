# MacTools (Menu Bar Boilerplate)

MacTools is a complete, minimal macOS menu bar app scaffold you can customize into your personal "Mac tools" suite. It ships with:

- A working menu bar app (AppKit)
- Dynamic status items (time, battery, Wi-Fi, clipboard)
- Quick actions for common system settings and utilities
- Build, package, and release scripts
- A Homebrew Cask template

> This repo is a boilerplate. The menu items are intentionally simple and safe (no private APIs). You can expand or replace them as needed.

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

## Customize the App

### Add or Remove Menu Items

Edit `Sources/MacTools/MacToolsApp.swift` to change menu items and actions.

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
