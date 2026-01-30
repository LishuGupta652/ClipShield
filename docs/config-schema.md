# Config Schema

```json
{
  "version": 1,
  "appTitle": "ClipShield",
  "menuBarIcon": {
    "symbolName": "shield.lefthalf.filled",
    "alertSymbolName": "exclamationmark.triangle.fill",
    "iconPath": "relative/path/to/icon.png",
    "accessibilityLabel": "ClipShield"
  },
  "monitoring": {
    "enabled": true,
    "pollIntervalSeconds": 0.75,
    "maxScanLength": 50000,
    "safePaste": {
      "enabled": false,
      "action": "mask",
      "notifyOnAutoRedact": true
    },
    "notifyOnDetect": false
  },
  "detection": {
    "builtins": {
      "pan": { "enabled": true },
      "iban": { "enabled": true },
      "ssn": { "enabled": true },
      "email": { "enabled": true },
      "phone": { "enabled": true }
    },
    "customRules": [
      {
        "id": "custom_id",
        "label": "Human name",
        "pattern": "\\b...\\b",
        "enabled": true,
        "strategy": "tokenize",
        "preserveLastDigits": 4,
        "maskCharacter": "*",
        "caseInsensitive": true
      }
    ]
  },
  "redaction": {
    "defaultStrategy": "mask",
    "maskCharacter": "*",
    "preserveLastDigits": 4,
    "perType": {
      "pan": { "strategy": "mask", "preserveLastDigits": 4 },
      "iban": { "strategy": "mask", "preserveLastDigits": 4 },
      "ssn": { "strategy": "mask", "preserveLastDigits": 4 },
      "email": { "strategy": "mask" },
      "phone": { "strategy": "mask", "preserveLastDigits": 2 }
    },
    "tokenization": {
      "prefix": "tok_",
      "hashLength": 10,
      "salt": ""
    }
  },
  "logging": {
    "enabled": false,
    "fileName": "clipshield.log"
  },
  "debug": {
    "showWindow": false
  }
}
```
