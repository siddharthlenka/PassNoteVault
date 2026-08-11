# Pass&Note Vault

Pass&Note Vault is an offline iOS vault for storing passwords and private notes on-device. It is built around local encrypted storage, manual encrypted backups, and optional biometric quick unlock.

## Features

- Store password records with account, optional username, and password fields.
- Store secure notes in the same local vault.
- Protect vault data with a Master Password.
- Optional Face ID, Touch ID, or Optic ID quick unlock.
- App-switcher privacy shield when the app leaves the foreground.
- Encrypted export and import support for passwords, notes, and full vault backups.
- Manual backup warnings when new passwords or notes have not been included in a full backup.
- Emergency web access guidance for decrypting exported files at `https://passandnote.com`.

## Security Model

Pass&Note Vault is local-first. Vault data is stored in an encrypted local database on the device and does not require a Pass&Note Vault account or server to unlock.

The Master Password is the primary credential for the vault. Biometric quick unlock is a convenience feature and is not a replacement for remembering the Master Password.

Encrypted exports remain tied to the Master Password that was active when the export file was created. If the Master Password is changed later, older exported files still require the older password.

## Backup Formats

- `.pnvault`: full encrypted vault backup containing passwords and secure notes.
- `.pnpass`: encrypted password package.
- `.pnnote`: encrypted secure-note package.
- `.txt`: unencrypted individual note export.

Keep encrypted backup files somewhere safe. If the app is uninstalled or the device is lost, local-only vault data may be lost unless a backup exists.

## Project Structure

- `PassNoteVault/App`: app root and lifecycle handling.
- `PassNoteVault/Core/Security`: vault encryption, key derivation, keychain, biometrics, password generation.
- `PassNoteVault/Database`: SQLCipher-backed GRDB database setup and migrations.
- `PassNoteVault/Features/Unboarding`: vault setup, unlock, passwords, notes, import/export, and settings screens.
- `PassNoteVault/DesignSystem`: shared SwiftUI styling and reusable components.
- `PassNoteVault/Resources`: asset catalog, app icon, and launch assets.

## Development

Open the workspace, not the project file:

```sh
open PassNoteVault.xcworkspace
```

The app uses CocoaPods dependencies checked into the repository:

- GRDB.swift
- SQLCipher

Build and run the `PassNoteVault` scheme from Xcode.

## Support

Support website: `https://passandnote.com`

Developer/Publisher: Siddharth Lenka

## License Notices

Open-source dependency notices are available inside the app under:

`Settings` -> `About Pass&Note Vault` -> `Open Source Licenses`
