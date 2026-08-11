//
//  AboutPassNoteView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import SwiftUI

enum AboutPassNoteRoute: Hashable {
    case aboutApp
    case comparison
    case security
    case recovery
    case exportImport
    case privacyPolicy
    case terms
    case licenses
}

struct AboutPassNoteView: View {
    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Pass&Note Vault")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Version \(Bundle.main.passNoteVersion) • Build \(Bundle.main.passNoteBuild)")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                settingsGroup("APP") {
                    aboutLink("About the App", route: .aboutApp)
                    Divider().background(AppTheme.Colors.border)
                    aboutLink("Why Pass&Note Vault", route: .comparison)
                }

                settingsGroup("SECURITY & HELP") {
                    aboutLink("How Pass&Note Vault Protects Your Data", route: .security)
                    aboutLink("Master Password & Recovery", route: .recovery)
                    aboutLink("Export & Import Guide", route: .exportImport)
                }

                settingsGroup("LEGAL") {
                    aboutLink("Privacy Policy", route: .privacyPolicy)
                    aboutLink("Terms & Conditions", route: .terms)
                    aboutLink("Open Source Licenses", route: .licenses)
                }
            }
        }
        .navigationTitle("About")
    }

    private func settingsGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            VStack(spacing: 0) {
                content()
            }
            .background(AppTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        }
    }

    private func aboutLink(_ title: String, route: AboutPassNoteRoute) -> some View {
        NavigationLink {
            AboutTextPage(route: route)
        } label: {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.mutedText)
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct AboutTextPage: View {
    let route: AboutPassNoteRoute

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text(title)
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(section.title)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Text(section.body)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        switch route {
        case .aboutApp: return "About the App"
        case .comparison: return "Why Pass&Note Vault"
        case .security: return "How Data Is Protected"
        case .recovery: return "Master Password & Recovery"
        case .exportImport: return "Export & Import Guide"
        case .privacyPolicy: return "Privacy Policy"
        case .terms: return "Terms & Conditions"
        case .licenses: return "Open Source Licenses"
        }
    }

    private var sections: [AboutSection] {
        switch route {
        case .aboutApp:
            return [
                AboutSection(title: "About Pass&Note Vault", body: "Pass&Note Vault is a privacy-focused offline vault for securely storing passwords and personal notes on your device. The app is designed around a simple principle: your vault belongs to you. Pass&Note Vault does not require a Pass&Note Vault account or a Pass&Note Vault server to access your vault. Your passwords and secure notes are stored locally in an encrypted database on your device. You can create encrypted export files to move or back up your information manually. You choose when to create an export and where to save it. Pass&Note Vault supports biometric quick unlock for convenience, while your Master Password remains the primary credential for sensitive security operations.")
            ]

        case .comparison:
            return [
                AboutSection(title: "Typical cloud password apps", body: "Many password managers are designed around accounts, cloud sync, subscriptions, browser extensions, and automatic cross-device access. Those features can be convenient, but they also mean users must trust more remote infrastructure, account security settings, and third-party service availability."),
                AboutSection(title: "Pass&Note Vault", body: "Pass&Note Vault focuses on local-first storage for passwords and secure notes. Your vault data stays encrypted on this device, and the app does not require a Pass&Note Vault online account to unlock or manage your local vault."),
                AboutSection(title: "Backups stay in your control", body: "Instead of automatic cloud sync, Pass&Note Vault lets you create encrypted export files when you choose. You decide where to store or share those files, and each encrypted export requires the Master Password that was active when the export was created."),
                AboutSection(title: "Passwords and notes together", body: "Pass&Note Vault is built for people who want both password records and private notes in one offline vault. It keeps the core workflow simple: add records, protect them locally, export encrypted backups, and restore when needed."),
                AboutSection(title: "Tradeoff", body: "Pass&Note Vault does not try to replace every cloud password manager feature. If you need automatic sync across many devices or browser autofill, a cloud-based manager may be more convenient. If you prefer an offline vault with manual encrypted backups and no required account, Pass&Note Vault is designed for that use case.")
            ]

        case .security:
            return [
                AboutSection(title: "Local encrypted storage", body: "Passwords and secure notes are stored in an encrypted local database. The database is protected using a randomly generated encryption key created specifically for your vault."),
                AboutSection(title: "Master Password", body: "Your Master Password is used to securely unlock access to your vault encryption key. Pass&Note Vault is designed so that your raw Master Password is not stored directly by the application."),
                AboutSection(title: "Biometric Quick Unlock", body: "Face ID or Touch ID can be enabled as a convenient way to unlock your vault. Biometric authentication does not replace your Master Password. Your device passcode is not used as a Pass&Note Vault password."),
                AboutSection(title: "App-switcher privacy", body: "Pass&Note Vault hides sensitive application content whenever the app leaves the foreground so passwords and notes are not exposed through the app-switcher preview."),
                AboutSection(title: "Encrypted backups", body: "Encrypted Pass&Note Vault exports use encryption separate from the local database encryption key. The Master Password active when the encrypted file is created is required to decrypt that file later."),
                AboutSection(title: "Security limitations", body: "No software can guarantee absolute protection. Security may be reduced if a device is jailbroken, compromised by malicious software, physically controlled by an attacker while unlocked, or if another person obtains the credentials required to decrypt your vault or exported files.")
            ]

        case .recovery:
            return [
                AboutSection(title: "Master Password", body: "Your Master Password is the primary credential protecting your Pass&Note Vault. Pass&Note Vault cannot recover or reveal a forgotten Master Password. If you forget it and biometric access is unavailable, your local encrypted vault may become permanently inaccessible."),
                AboutSection(title: "Biometrics are not recovery", body: "Biometric Quick Unlock is a convenience feature and should not be treated as a recovery method for a forgotten Master Password."),
                AboutSection(title: "Changing your Master Password", body: "Changing the Master Password used by your current vault does not automatically change the password protecting encrypted backup files you created previously. A backup created while Password A was active will continue to require Password A. If you later change your vault to Password B, new encrypted exports will use Password B. Create a new full encrypted vault backup after changing your Master Password.")
            ]

        case .exportImport:
            return [
                AboutSection(title: ".pnpass", body: "An encrypted package containing one or more password records. Passwords can only be exported from Pass&Note Vault in encrypted form. A .pnpass file requires the Master Password that was active when the file was created."),
                AboutSection(title: ".pnnote", body: "An encrypted package containing one or more secure notes. A .pnnote file requires the Master Password that was active when the file was created."),
                AboutSection(title: ".pnvault", body: "A complete encrypted Pass&Note Vault backup containing passwords and secure notes. Use this format when you want to create a full backup or move your vault data to another device."),
                AboutSection(title: ".txt", body: "A normal unencrypted text file containing a single note. A .txt export is readable by anyone who obtains access to that file."),
                AboutSection(title: "Importing data", body: "Importing a password package, note package, or full vault backup into an existing vault adds the imported records to the current vault. Existing records are not automatically deleted. Importing the same file more than once may create duplicate entries. During encrypted import, Pass&Note Vault asks for the Master Password used when that export was created. This Backup Password may be different from the current vault Master Password."),
                AboutSection(title: "Emergency Web Access", body: "A web version is available for emergency use at https://passandnote.com. You can use it to decrypt and read encrypted .pnvault, .pnpass, and .pnnote files when you do not have access to the app. Only open encrypted export files on devices and browsers you trust, and keep your Master Password private.")
            ]

        case .privacyPolicy:
            return [
                AboutSection(title: "Effective Date", body: "[Insert release date]"),
                AboutSection(title: "Overview", body: "Pass&Note Vault is designed as a privacy-focused local vault. This Privacy Policy explains how information is handled when you use Pass&Note Vault."),
                AboutSection(title: "Vault Data", body: "Passwords, secure notes, and related vault information are stored locally in an encrypted database on your device. Pass&Note Vault does not require you to create a Pass&Note Vault online account in order to use the vault. Pass&Note Vault does not intentionally transmit the contents of your vault to developer-operated servers."),
                AboutSection(title: "Master Password", body: "Pass&Note Vault is designed so that your raw Master Password is not stored directly by the application. Your Master Password is used as part of the cryptographic process that allows access to your encrypted vault. Pass&Note Vault cannot recover a forgotten Master Password."),
                AboutSection(title: "Biometrics", body: "If you enable Face ID or Touch ID, biometric verification is performed using security functionality provided by the operating system. Pass&Note Vault does not receive or store your fingerprint image, facial image, or underlying biometric template. Biometric Quick Unlock is optional."),
                AboutSection(title: "Exports and Backups", body: "Pass&Note Vault allows you to manually export encrypted password packages, encrypted note packages, encrypted full-vault backups, and unencrypted individual notes. You choose when an export occurs and where the resulting file is saved or shared. Files saved or shared through Files, iCloud Drive, email, messaging services, cloud storage providers, or other applications are subject to those services' privacy and security practices."),
                AboutSection(title: "Unencrypted Note Exports", body: "An unencrypted .txt note is not protected by Pass&Note Vault encryption after export. Anyone who obtains access to that exported file may be able to read its contents."),
                AboutSection(title: "Clipboard", body: "When you choose to copy a password, the value may temporarily be placed on the system clipboard so you can paste it into another application. Pass&Note Vault may use operating-system capabilities to limit how long copied password data remains available, according to your selected clipboard-protection setting."),
                AboutSection(title: "Analytics, Advertising and Tracking", body: "Pass&Note Vault does not include advertising or behavioral tracking, and does not use vault contents for analytics."),
                AboutSection(title: "Network and Cloud Features", body: "Pass&Note Vault does not provide automatic cloud synchronization for Pass&Note Vault in V1. If cloud synchronization, analytics, remote crash reporting, accounts, or other network services are introduced in a future version, this Privacy Policy must be updated."),
                AboutSection(title: "Data Deletion", body: "Vault data can be deleted from within the application where deletion functionality is available. Deleting the application may remove application data stored in the app container, subject to operating-system behavior. Exported files saved elsewhere are outside the Pass&Note Vault app container and must be deleted separately."),
                AboutSection(title: "Security", body: "Pass&Note Vault uses technical safeguards designed to protect locally stored vault information. However, no software, device, storage system, or encryption implementation can guarantee absolute security. Users are responsible for protecting their Master Password, their device, and exported backup files."),
                AboutSection(title: "Children", body: "Pass&Note Vault is a general-purpose privacy utility and is not specifically designed to collect personal information from children. Because the application does not operate a Pass&Note Vault account service in V1, the developer does not intentionally request personal information from children through an account-registration process."),
                AboutSection(title: "Changes", body: "This Privacy Policy may be updated when Pass&Note Vault features, data practices, or legal requirements change."),
                AboutSection(title: "Contact", body: "Developer/Publisher: Siddharth Lenka\n\nContact: https://passandnote.com")
            ]

        case .terms:
            return [
                AboutSection(title: "Effective Date", body: "[Insert release date]"),
                AboutSection(title: "Acceptance", body: "By downloading, installing, or using Pass&Note Vault, you agree to these Terms & Conditions. If you do not agree with these terms, do not use the application."),
                AboutSection(title: "Purpose", body: "Pass&Note Vault is a software utility designed to allow users to locally store and manage passwords, secure notes, and encrypted backup files."),
                AboutSection(title: "Your Master Password", body: "You are responsible for creating, remembering, and protecting your Master Password. Pass&Note Vault is designed so that the developer cannot recover a forgotten Master Password. Loss of the Master Password may result in permanent loss of access to encrypted vault data or encrypted backup files."),
                AboutSection(title: "Biometric Unlock", body: "Face ID or Touch ID may be offered as an optional convenience feature. Biometric Quick Unlock is not a replacement or recovery mechanism for the Master Password."),
                AboutSection(title: "Your Data", body: "You are responsible for the information you store in Pass&Note Vault. You should maintain appropriate encrypted backups of information that you cannot afford to lose."),
                AboutSection(title: "Backup Files", body: "Encrypted export files require the Master Password that was used when the export was created. If you change your Master Password, previously created encrypted backups may continue to require the previous password."),
                AboutSection(title: "Unencrypted Exports", body: "Pass&Note Vault may allow individual notes to be exported as unencrypted text files. Once exported in unencrypted form, those files are no longer protected by Pass&Note Vault encryption."),
                AboutSection(title: "Third-Party Storage and Services", body: "When you choose to save or share exported files using iCloud Drive, Files, another cloud-storage service, email, messaging software, or another application, your use of that service is subject to the provider's own terms and privacy practices."),
                AboutSection(title: "Prohibited Use", body: "You may not use Pass&Note Vault in a manner that violates applicable law, infringes the rights of others, interferes with the operation of the application, or attempts to distribute malicious modifications of the software."),
                AboutSection(title: "Security Limitations", body: "Pass&Note Vault is designed to provide strong privacy and security protections, but no software can guarantee absolute security. Security may be reduced on jailbroken, compromised, modified, or maliciously controlled devices."),
                AboutSection(title: "Availability", body: "Pass&Note Vault may be updated, modified, or discontinued. Compatibility may change as operating systems, hardware, security APIs, and third-party dependencies evolve."),
                AboutSection(title: "No Warranty", body: "To the extent permitted by applicable law, Pass&Note Vault is provided on an as available basis without guarantees that the application will always operate without interruption, errors, or data loss."),
                AboutSection(title: "Limitation of Responsibility", body: "To the extent permitted by applicable law, the developer is not responsible for losses resulting from forgotten Master Passwords, deleted vaults, lost devices, compromised devices, lost or damaged backup files, unencrypted exports, third-party storage providers, or actions taken by users outside the application's control. This section should be reviewed by qualified legal counsel before commercial release."),
                AboutSection(title: "Changes", body: "These Terms & Conditions may be updated when application functionality, distribution requirements, or applicable law changes."),
                AboutSection(title: "Contact", body: "Developer/Publisher: Siddharth Lenka\n\nContact: https://passandnote.com")
            ]

        case .licenses:
            return [
                AboutSection(title: "Open Source Software", body: "Pass&Note Vault includes open-source dependencies installed through CocoaPods. The following notices apply to the versions bundled with this app."),
                AboutSection(title: "GRDB.swift", body: """
                Copyright (C) 2015-2023 Gwendal Roué

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """),
                AboutSection(title: "SQLCipher", body: """
                Copyright (c) 2025, ZETETIC LLC
                All rights reserved.

                Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

                * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
                * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
                * Neither the name of the ZETETIC LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

                THIS SOFTWARE IS PROVIDED BY ZETETIC LLC ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ZETETIC LLC BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
                """)
            ]
        }
    }
}

struct AboutSection {
    let title: String
    let body: String
}

extension Bundle {
    var passNoteVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    var passNoteBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}
