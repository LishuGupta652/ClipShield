# Config Schema (Reference)

This is an informal schema for the `config.json` file.

```
Config
  version: number
  appTitle: string
  menuBarIcon:
    symbolName?: string
    iconPath?: string
    accessibilityLabel?: string
  statusSection:
    title: string
    showTime: boolean
    showBattery: boolean
    showWiFi: boolean
    showClipboard: boolean
    timeFormat?: string
  sections: MenuSection[]
  footer:
    showReloadConfig: boolean
    showOpenConfig: boolean
    showRevealConfig: boolean
    showRelaunch: boolean
    showQuit: boolean
  debug:
    showWindow: boolean

MenuSection
  title?: string
  items: MenuItem[]

MenuItem
  type: string
  title?: string
  paneID?: string
  url?: string
  path?: string
  command?: string
  arguments?: string[]
  script?: string
  text?: string
  enabled?: boolean
  keyEquivalent?: string
```

See [Actions](actions.md) for supported `type` values.
