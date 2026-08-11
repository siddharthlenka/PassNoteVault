//
//  FullVaultRestoreView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct FullVaultRestoreView: View {
    @Environment(\.dismiss) private var dismiss

    var resetUnusedVaultBeforeRestore = false
    let onRestored: () -> Void

    @StateObject private var setupViewModel = VaultSetupViewModel()
    @State private var isShowingFileImporter = false
    @State private var isConfirmingBackupPassword = false
    @State private var pendingImportData: Data?
    @State private var pendingSummary: VaultImportSummary?
    @State private var errorMessage: String?
    @State private var isRestoring = false

    private var canRestore: Bool {
        pendingSummary != nil && setupViewModel.canContinueFromPassword
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Restore From Backup")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Restore a full encrypted Pass&Note Vault backup into a new local vault.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                if let pendingSummary {
                    restoreSummary(pendingSummary)
                    newMasterPasswordSection
                } else {
                    InfoWarningCard(
                        kind: .info,
                        title: "Full backups only",
                        message: "Choose a .pnvault file. The Backup Password decrypts the file; your new Master Password protects this device's new vault."
                    )

                    AppButton(
                        title: "Choose .pnvault File",
                        systemImage: "tray.and.arrow.down"
                    ) {
                        errorMessage = nil
                        isShowingFileImporter = true
                    }
                }

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Restore failed",
                        message: errorMessage
                    )
                }

                if pendingSummary != nil {
                    AppButton(
                        title: "Restore Vault",
                        systemImage: "lock.rotation",
                        isEnabled: canRestore,
                        isLoading: isRestoring
                    ) {
                        restorePendingBackup()
                    }
                }

                AppButton(
                    title: "Cancel",
                    systemImage: "xmark",
                    kind: .secondary
                ) {
                    clearRestoreState()
                    dismiss()
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImportResult(result)
        }
        .sheet(isPresented: $isConfirmingBackupPassword) {
            MasterPasswordConfirmationView(
                title: "Backup Password",
                message: "Enter the Master Password that was used when this backup was created.",
                passwordTitle: "Backup Password",
                passwordPlaceholder: "Enter backup password"
            ) { backupPassword in
                decryptPendingImport(backupPassword: backupPassword)
            }
        }
    }

    private func restoreSummary(_ summary: VaultImportSummary) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Restore Pass&Note Vault Backup")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primaryText)

            RestoreSummaryRow(title: "Passwords", value: "\(summary.passwordCount)")
            RestoreSummaryRow(title: "Secure Notes", value: "\(summary.noteCount)")
            RestoreSummaryRow(title: "Backup created", value: summary.container.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
    }

    private var newMasterPasswordSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Create New Local Master Password")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primaryText)

            AppSecureField(
                title: "New Master Password",
                placeholder: "Enter new master password",
                text: $setupViewModel.masterPassword
            )

            AppSecureField(
                title: "Confirm New Master Password",
                placeholder: "Re-enter new master password",
                text: $setupViewModel.confirmPassword,
                error: setupViewModel.passwordMatchError
            )

            InfoWarningCard(
                kind: .info,
                title: "New local vault key",
                message: "This device will generate a new random vault key. The Backup Password is not reused as your local credential unless you choose the same password."
            )
        }
    }

    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                return
            }

            try ImportSupport.validateExtension(for: url, allowedExtensions: ["pnvault"])
            pendingImportData = try ImportSupport.readFileData(from: url)
            isConfirmingBackupPassword = true
        } catch {
            errorMessage = ImportSupport.message(for: error)
        }
    }

    private func decryptPendingImport(backupPassword: String) -> String? {
        guard let pendingImportData else {
            return "Choose a vault backup first."
        }

        do {
            let package = try ImportDecryptionService.decrypt(
                data: pendingImportData,
                backupPassword: backupPassword,
                expectedContentType: .fullVault,
                payloadType: FullVaultExportPayload.self
            )

            guard package.payload.payloadVersion == 1 else {
                throw ImportDecryptionError.unsupportedVersion
            }

            let summary = VaultImportSummary(
                container: package.container,
                payload: package.payload
            )

            guard summary.totalCount > 0 else {
                throw ImportSupportError.emptyImport
            }

            pendingSummary = summary
            isConfirmingBackupPassword = false
            errorMessage = nil
            return nil
        } catch {
            return ImportSupport.message(for: error)
        }
    }

    private func restorePendingBackup() {
        guard let pendingSummary else {
            errorMessage = "Choose and decrypt a vault backup first."
            return
        }

        guard setupViewModel.canContinueFromPassword else {
            errorMessage = "Create and confirm a strong new Master Password."
            return
        }

        isRestoring = true
        var didCreateLocalVault = false

        do {
            if resetUnusedVaultBeforeRestore {
                try VaultDatabase.shared.resetUnusedVault()
            }

            try VaultDatabase.shared.create(masterPassword: setupViewModel.masterPassword)
            didCreateLocalVault = true
            try ImportSupport.importFullVaultPayload(pendingSummary.payload)
            VaultLifecycleMetadata.markVaultActivated()
            setupViewModel.clearSensitiveInputs()
            clearRestoreState()
            isRestoring = false
            onRestored()
            dismiss()
        } catch {
            if didCreateLocalVault, VaultLifecycleMetadata.canResetUnusedVault {
                try? VaultDatabase.shared.resetUnusedVault()
            }
            isRestoring = false
            errorMessage = ImportSupport.message(for: error)
        }
    }

    private func clearRestoreState() {
        pendingImportData = nil
        pendingSummary = nil
        isConfirmingBackupPassword = false
        setupViewModel.clearSensitiveInputs()
    }
}

private struct RestoreSummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
    }
}
