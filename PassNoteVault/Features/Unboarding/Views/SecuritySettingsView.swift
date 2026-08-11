//
//  SecuritySettingsView.swift
//  PassNoteVault
//

import SwiftUI

enum BiometricSettingsAction {
    case enable
    case disable

    var title: String {
        switch self {
        case .enable:
            return "Enable Quick Unlock"
        case .disable:
            return "Disable Quick Unlock"
        }
    }

    var buttonTitle: String {
        switch self {
        case .enable:
            return "Enable"
        case .disable:
            return "Disable"
        }
    }
}

private enum SettingsSheet: Identifiable {
    case biometric(BiometricSettingsAction)
    case changeMasterPassword
    case vaultImport
    case vaultExport

    var id: String {
        switch self {
        case .biometric(let action):
            return "biometric-\(action.id)"
        case .changeMasterPassword:
            return "changeMasterPassword"
        case .vaultImport:
            return "vaultImport"
        case .vaultExport:
            return "vaultExport"
        }
    }
}

struct SecuritySettingsView: View {
    @AppStorage(BiometricVaultKeyService.isEnabledKey) private var biometricQuickUnlockEnabled = false
    @AppStorage(VaultSettingsMetadata.autoLockDurationKey) private var autoLockDurationRaw = AutoLockDuration.immediately.rawValue
    @AppStorage(VaultSettingsMetadata.clipboardClearDurationKey) private var clipboardClearDurationRaw = ClipboardClearDuration.thirtySeconds.rawValue
    @AppStorage(VaultSettingsMetadata.lastFullBackupDateKey) private var lastFullBackupTimestamp = 0.0
    @AppStorage(VaultSettingsMetadata.backupUpdateRequiredKey) private var backupUpdateRequired = false
    @AppStorage(VaultSettingsMetadata.unbackedUpPasswordChangeCountKey) private var unbackedUpPasswordChangeCount = 0
    @AppStorage(VaultSettingsMetadata.unbackedUpNoteChangeCountKey) private var unbackedUpNoteChangeCount = 0
    @AppStorage(VaultSettingsMetadata.masterPasswordChangedSinceBackupKey) private var masterPasswordChangedSinceBackup = false

    @State private var activeSheet: SettingsSheet?
    @State private var masterPassword = ""
    @State private var currentMasterPassword = ""
    @State private var newMasterPassword = ""
    @State private var confirmNewMasterPassword = ""
    @State private var changePasswordErrorMessage: String?
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    private let biometricService = BiometricVaultKeyService.shared

    private var biometricName: String {
        biometricService.biometricDisplayName
    }

    private var autoLockDuration: Binding<AutoLockDuration> {
        Binding(
            get: { AutoLockDuration(rawValue: autoLockDurationRaw) ?? .immediately },
            set: { autoLockDurationRaw = $0.rawValue }
        )
    }

    private var clipboardClearDuration: Binding<ClipboardClearDuration> {
        Binding(
            get: { ClipboardClearDuration(rawValue: clipboardClearDurationRaw) ?? .thirtySeconds },
            set: { clipboardClearDurationRaw = $0.rawValue }
        )
    }

    private var backupStatus: BackupStatus {
        if backupUpdateRequired {
            return .updateRequired
        }

        return lastFullBackupTimestamp > 0 ? .upToDate : .neverBackedUp
    }

    private var lastFullBackupText: String {
        guard lastFullBackupTimestamp > 0 else {
            return "Never"
        }

        return Date(timeIntervalSince1970: lastFullBackupTimestamp)
            .formatted(date: .abbreviated, time: .shortened)
    }

    private var newPasswordValidation: PasswordValidationResult {
        PasswordValidator.validate(newMasterPassword)
    }

    private var newPasswordMatchError: String? {
        guard !confirmNewMasterPassword.isEmpty else { return nil }
        return newMasterPassword == confirmNewMasterPassword ? nil : "Passwords do not match."
    }

    private var newPasswordDifferenceError: String? {
        guard !currentMasterPassword.isEmpty,
              !newMasterPassword.isEmpty,
              currentMasterPassword == newMasterPassword else {
            return nil
        }

        return "New Master Password must be different from the current password."
    }

    private var canChangeMasterPassword: Bool {
        !currentMasterPassword.isEmpty &&
        newPasswordValidation.isStrong &&
        !confirmNewMasterPassword.isEmpty &&
        newMasterPassword == confirmNewMasterPassword &&
        currentMasterPassword != newMasterPassword
    }

    private var backupWarningMessage: String? {
        let hasNeverBackedUp = lastFullBackupTimestamp <= 0
        guard hasNeverBackedUp ||
              backupUpdateRequired ||
              unbackedUpPasswordChangeCount > 0 ||
              unbackedUpNoteChangeCount > 0 ||
              masterPasswordChangedSinceBackup else {
            return nil
        }

        var messages: [String] = []

        if hasNeverBackedUp {
            messages.append("You have not created a full backup yet.")
        }

        let changeSummary = backupChangeSummary
        if !changeSummary.isEmpty {
            let verb = (unbackedUpPasswordChangeCount + unbackedUpNoteChangeCount) == 1 ? "has" : "have"
            messages.append("\(changeSummary) \(verb) not been included in a full backup.")
        }

        if masterPasswordChangedSinceBackup {
            messages.append("Your Master Password changed after the last backup. Old exported vault files still require the old Master Password used when they were created.")
        }

        messages.append("Please back up the vault so you do not lose your data if the app is uninstalled or your phone is lost.")
        return messages.joined(separator: " ")
    }

    private var backupChangeSummary: String {
        var parts: [String] = []

        if unbackedUpPasswordChangeCount > 0 {
            parts.append("\(unbackedUpPasswordChangeCount) new \(unbackedUpPasswordChangeCount == 1 ? "password" : "passwords")")
        }

        if unbackedUpNoteChangeCount > 0 {
            parts.append("\(unbackedUpNoteChangeCount) new \(unbackedUpNoteChangeCount == 1 ? "note" : "notes")")
        }

        return parts.joined(separator: " and ")
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Settings")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Manage vault security, privacy, backup, and app information.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                if let statusMessage {
                    InfoWarningCard(
                        kind: .success,
                        title: "Settings updated",
                        message: statusMessage
                    )
                }

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Settings error",
                        message: errorMessage
                    )
                }

                if let backupWarningMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Backup needed",
                        message: backupWarningMessage
                    )
                }

                settingsGroup("SECURITY") {
                    biometricRow
                    Divider().background(AppTheme.Colors.border)
                    autoLockRow
                    Divider().background(AppTheme.Colors.border)
                    Button {
                        errorMessage = nil
                        statusMessage = nil
                        clearChangePasswordInputs()
                        changePasswordErrorMessage = nil
                        activeSheet = .changeMasterPassword
                    } label: {
                        settingsNavigationRow(title: "Change Master Password", systemImage: "key.horizontal")
                    }
                    .buttonStyle(.plain)
                }

                settingsGroup("PRIVACY") {
                    clipboardRow
                }

                settingsGroup("DATA & BACKUP") {
                    Button {
                        activeSheet = .vaultImport
                    } label: {
                        settingsNavigationRow(title: "Import Vault", systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.plain)

                    Divider().background(AppTheme.Colors.border)

                    Button {
                        activeSheet = .vaultExport
                    } label: {
                        settingsNavigationRow(title: "Export Vault", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.plain)

                    Divider().background(AppTheme.Colors.border)

                    settingsValueRow(
                        title: "Backup Status",
                        value: backupStatus.title,
                        systemImage: "checkmark.shield"
                    )

                    Divider().background(AppTheme.Colors.border)

                    settingsValueRow(
                        title: "Last Full Backup",
                        value: lastFullBackupText,
                        systemImage: "clock"
                    )
                }

                settingsGroup("ABOUT") {
                    NavigationLink {
                        AboutPassNoteView()
                    } label: {
                        settingsNavigationRow(title: "About Pass&Note Vault", systemImage: "info.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .biometric(let action):
                masterPasswordPrompt(for: action)

            case .changeMasterPassword:
                changeMasterPasswordPrompt()

            case .vaultImport:
                VaultImportView {
                    statusMessage = "Vault data imported successfully."
                }

            case .vaultExport:
                VaultExportView {
                    statusMessage = "Full encrypted vault backup completed."
                }
            }
        }
    }

    private var biometricRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: biometricQuickUnlockEnabled ? "checkmark.shield.fill" : "lock.shield")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(biometricName) Quick Unlock")
                    .font(AppTheme.Typography.callout.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(biometricQuickUnlockEnabled ? "Enabled" : "Off")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { biometricQuickUnlockEnabled },
                set: { isEnabled in
                    errorMessage = nil
                    statusMessage = nil
                    masterPassword = ""
                    activeSheet = .biometric(isEnabled ? .enable : .disable)
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(AppTheme.Spacing.md)
    }

    private var autoLockRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "timer")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 28)

                Text("Auto-Lock")
                    .font(AppTheme.Typography.callout.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Spacer()
            }

            Picker("Auto-Lock", selection: autoLockDuration) {
                ForEach(AutoLockDuration.allCases) { duration in
                    Text(duration.title)
                        .tag(duration)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(AppTheme.Spacing.md)
    }

    private var clipboardRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 28)

                Text("Clear Copied Passwords")
                    .font(AppTheme.Typography.callout.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Spacer()
            }

            Picker("Clear Copied Passwords", selection: clipboardClearDuration) {
                ForEach(ClipboardClearDuration.allCases) { duration in
                    Text(duration.title)
                        .tag(duration)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(AppTheme.Spacing.md)
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

    private func settingsValueRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 28)

            Text(title)
                .font(AppTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(AppTheme.Spacing.md)
    }

    private func settingsNavigationRow(title: String, systemImage: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 28)

            Text(title)
                .font(AppTheme.Typography.callout.weight(.semibold))
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

    private func masterPasswordPrompt(for action: BiometricSettingsAction) -> some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(action.title)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Enter your master password to confirm this security change.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                AppSecureField(
                    title: "Master Password",
                    placeholder: "Enter master password",
                    text: $masterPassword
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    AppButton(
                        title: "Cancel",
                        systemImage: "xmark",
                        kind: .secondary
                    ) {
                        activeSheet = nil
                        masterPassword = ""
                    }

                    AppButton(
                        title: action.buttonTitle,
                        systemImage: action == .enable ? "checkmark.shield" : "xmark.shield"
                    ) {
                        perform(action)
                    }
                }
            }
        }
    }

    private func changeMasterPasswordPrompt() -> some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Change Master Password")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Enter your current Master Password, then create a new strong password.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    AppSecureField(
                        title: "Current Master Password",
                        placeholder: "Enter current password",
                        text: $currentMasterPassword
                    )

                    AppSecureField(
                        title: "New Master Password",
                        placeholder: "Enter new password",
                        text: $newMasterPassword,
                        error: newPasswordDifferenceError
                    )

                    AppSecureField(
                        title: "Confirm New Master Password",
                        placeholder: "Re-enter new password",
                        text: $confirmNewMasterPassword,
                        error: newPasswordMatchError
                    )
                }

                ChangePasswordChecklist(result: newPasswordValidation)

                if let changePasswordErrorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Password change failed",
                        message: changePasswordErrorMessage
                    )
                }

                InfoWarningCard(
                    kind: .warning,
                    title: "Backup password reminder",
                    message: "Encrypted exports continue to use the Master Password that was active when each file was created. After changing your Master Password, remember the password used for older exports and create a new full vault backup."
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    AppButton(
                        title: "Cancel",
                        systemImage: "xmark",
                        kind: .secondary
                    ) {
                        activeSheet = nil
                        clearChangePasswordInputs()
                        changePasswordErrorMessage = nil
                    }

                    AppButton(
                        title: "Change",
                        systemImage: "checkmark.shield",
                        isEnabled: canChangeMasterPassword
                    ) {
                        changeMasterPassword()
                    }
                }
            }
        }
    }

    private func perform(_ action: BiometricSettingsAction) {
        defer {
            masterPassword = ""
        }

        do {
            var vaultKey = try VaultDatabase.shared.recoverVaultKey(masterPassword: masterPassword)

            defer {
                vaultKey.resetBytes(in: 0..<vaultKey.count)
            }

            switch action {
            case .enable:
                try biometricService.enable(vaultKey: vaultKey)
            case .disable:
                biometricService.disable()
            }

            biometricQuickUnlockEnabled = biometricService.isEnabled
            errorMessage = nil
            statusMessage = "\(biometricName) Quick Unlock is \(biometricQuickUnlockEnabled ? "enabled" : "disabled")."
            activeSheet = nil
        } catch BiometricVaultKeyError.unavailable {
            errorMessage = "\(biometricName) is not available or not enrolled on this device."
            activeSheet = nil
        } catch {
            errorMessage = "The master password could not be verified."
            activeSheet = nil
        }
    }

    private func changeMasterPassword() {
        guard currentMasterPassword != newMasterPassword else {
            changePasswordErrorMessage = "Choose a new Master Password that is different from the current one."
            return
        }

        do {
            try VaultDatabase.shared.changeMasterPassword(
                currentPassword: currentMasterPassword,
                newPassword: newMasterPassword
            )
            VaultSettingsMetadata.markMasterPasswordChangedSinceBackup()
            backupUpdateRequired = true
            masterPasswordChangedSinceBackup = true
            statusMessage = "Master Password changed. Create a new full backup when possible."
            errorMessage = nil
            activeSheet = nil
            clearChangePasswordInputs()
            changePasswordErrorMessage = nil
        } catch {
            changePasswordErrorMessage = "The current Master Password could not be verified."
            currentMasterPassword = ""
        }
    }

    private func clearChangePasswordInputs() {
        currentMasterPassword = ""
        newMasterPassword = ""
        confirmNewMasterPassword = ""
    }
}

private struct ChangePasswordChecklist: View {
    let result: PasswordValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("New password strength")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ChangePasswordRuleRow(title: "At least 12 characters", isValid: result.hasMinimumLength)
                ChangePasswordRuleRow(title: "Uppercase letter", isValid: result.hasUppercase)
                ChangePasswordRuleRow(title: "Lowercase letter", isValid: result.hasLowercase)
                ChangePasswordRuleRow(title: "Number", isValid: result.hasNumber)
                ChangePasswordRuleRow(title: "Special character", isValid: result.hasSpecialCharacter)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        }
    }
}

private struct ChangePasswordRuleRow: View {
    let title: String
    let isValid: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isValid ? AppTheme.Colors.success : AppTheme.Colors.mutedText)

            Text(title)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(isValid ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)

            Spacer()
        }
    }
}

extension BiometricSettingsAction: Identifiable {
    var id: String {
        switch self {
        case .enable:
            return "enable"
        case .disable:
            return "disable"
        }
    }
}
