//
//  VaultImportView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 09/08/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct VaultImportView: View {
    @Environment(\.dismiss) private var dismiss

    let onImported: () -> Void

    @State private var isShowingFileImporter = false
    @State private var isConfirmingBackupPassword = false
    @State private var pendingImportData: Data?
    @State private var pendingSummary: VaultImportSummary?
    @State private var isShowingImportPreview = false
    @State private var errorMessage: String?

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Import Vault")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Merge an encrypted full backup into your current vault.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                InfoWarningCard(
                    kind: .warning,
                    title: "Adds to current vault",
                    message: "Imported passwords and notes will be added as new records. Existing items will not be deleted."
                )

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Import failed",
                        message: errorMessage
                    )
                }

                AppButton(
                    title: "Choose .pnvault File",
                    systemImage: "tray.and.arrow.down"
                ) {
                    errorMessage = nil
                    isShowingFileImporter = true
                }

                AppButton(
                    title: "Cancel",
                    systemImage: "xmark",
                    kind: .secondary
                ) {
                    clearImportState()
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
        .alert("Import Vault Backup", isPresented: $isShowingImportPreview) {
            Button("Cancel", role: .cancel) {
                clearImportState()
            }

            Button("Import") {
                importPendingSummary()
            }
        } message: {
            if let pendingSummary {
                Text("This backup contains:\n\n\(pendingSummary.passwordCount) Passwords\n\(pendingSummary.noteCount) Secure Notes\n\nThese items will be added to your current vault. Existing items will not be deleted.")
            } else {
                Text("These items will be added to your current vault.")
            }
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
            DispatchQueue.main.async {
                isShowingImportPreview = true
            }
            errorMessage = nil
            return nil
        } catch {
            return ImportSupport.message(for: error)
        }
    }

    private func importPendingSummary() {
        guard let pendingSummary else {
            return
        }

        do {
            try ImportSupport.importFullVaultPayload(pendingSummary.payload)
            onImported()
            clearImportState()
            dismiss()
        } catch {
            errorMessage = ImportSupport.message(for: error)
        }
    }

    private func clearImportState() {
        pendingImportData = nil
        pendingSummary = nil
        isConfirmingBackupPassword = false
        isShowingImportPreview = false
    }
}
