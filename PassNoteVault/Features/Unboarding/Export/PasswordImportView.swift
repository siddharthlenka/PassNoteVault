//
//  PasswordImportView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PasswordImportView: View {
    @Environment(\.dismiss) private var dismiss

    let onImport: ([PasswordEntry]) -> Void

    @State private var isShowingFileImporter = false
    @State private var isConfirmingBackupPassword = false
    @State private var pendingImportData: Data?
    @State private var pendingPasswords: [PasswordEntry] = []
    @State private var isShowingImportPreview = false
    @State private var errorMessage: String?

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Import Passwords")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Import an encrypted Pass&Note Vault password package.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                InfoWarningCard(
                    kind: .info,
                    title: "Backup password required",
                    message: "Enter the Master Password that was used when this backup was created. Imported passwords are added as new records."
                )

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Import failed",
                        message: errorMessage
                    )
                }

                AppButton(
                    title: "Choose .pnpass File",
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
        .alert("Import Passwords", isPresented: $isShowingImportPreview) {
            Button("Cancel", role: .cancel) {
                clearImportState()
            }

            Button("Import \(pendingPasswords.count) Passwords") {
                onImport(pendingPasswords)
                clearImportState()
                dismiss()
            }
        } message: {
            Text("\(pendingPasswords.count) passwords found. Importing the same backup more than once may create duplicate entries.")
        }
    }

    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                return
            }

            try ImportSupport.validateExtension(for: url, allowedExtensions: ["pnpass"])
            pendingImportData = try ImportSupport.readFileData(from: url)
            isConfirmingBackupPassword = true
        } catch {
            errorMessage = ImportSupport.message(for: error)
        }
    }

    private func decryptPendingImport(backupPassword: String) -> String? {
        guard let pendingImportData else {
            return "Choose a password package first."
        }

        do {
            let package = try ImportDecryptionService.decrypt(
                data: pendingImportData,
                backupPassword: backupPassword,
                expectedContentType: .passwords,
                payloadType: PasswordExportPayload.self
            )

            guard package.payload.payloadVersion == 1 else {
                throw ImportDecryptionError.unsupportedVersion
            }

            let passwords = try package.payload.passwords.map(ImportSupport.passwordEntry(from:))
            guard !passwords.isEmpty else {
                throw ImportSupportError.emptyImport
            }

            pendingPasswords = passwords
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

    private func clearImportState() {
        pendingImportData = nil
        pendingPasswords = []
        isConfirmingBackupPassword = false
        isShowingImportPreview = false
    }
}
