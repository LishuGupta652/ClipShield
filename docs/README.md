# MacTools Documentation

MacTools is a customizable macOS menu bar toolkit. This documentation covers setup, configuration, packaging, and distribution.

## Menu Preview

<p align="center">
  <img src="Menu_Preview.png" alt="MacTools menu preview" width="320" />
</p>

## What You Get

- Menu bar status items (time, battery, Wi-Fi, clipboard)
- Config-driven menus and actions
- Packaging and release scripts
- Homebrew Cask template

## Quick Start

```bash
swift run
```

The app creates a default config at:

```
~/Library/Application Support/MacTools/config.json
```

Edit it, then choose **Reload Config** from the menu bar.

## Docs Map

- [Getting Started](getting-started.md)
- [Configuration](configuration.md)
- [Actions](actions.md)
- [Packaging & Release](packaging.md)
- [Homebrew Cask](cask.md)
- [Deploy Docs](deploy.md)
- [Troubleshooting](troubleshooting.md)

## Customize the Docs Site

- Edit pages in `docs/*.md`
- Update navigation in `docs/_sidebar.md` and `docs/_navbar.md`
- Adjust styling in `docs/styles.css`
