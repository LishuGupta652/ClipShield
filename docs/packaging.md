# Packaging & Release

## Create an App Bundle

```bash
./scripts/package_app.sh 0.1.0
```

The app bundle is created under:

```
dist/ClipShield.app
```

## Create a Release ZIP

```bash
./scripts/release.sh 0.1.0
```

This creates:

```
dist/ClipShield-0.1.0.zip
```

## Signing & Notarization

```bash
./scripts/sign_notarize.sh dist/ClipShield.app "Developer ID Application: Your Name" you@example.com TEAMID APP_SPECIFIC_PASSWORD
```
