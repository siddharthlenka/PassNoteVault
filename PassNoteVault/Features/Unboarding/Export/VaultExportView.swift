//
//  VaultExportView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import SwiftUI

struct VaultExportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var passwords: [PasswordEntry] = []
    @State private var notes: [SecureNote] = []
    @State private var errorMessage: String?
    @State private var isConfirmingMasterPassword = false
    @State private var exportDocument = EncryptedExportDocument(
        data: Data(),
        contentType: .passNoteEncryptedExport
    )
    @State private var exportFilename = ExportSupport.vaultBackupFilename()
    @State private var isShowingFileExporter = false

    private var totalItemCount: Int {
        passwords.count + notes.count
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Export Vault")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Create one encrypted backup of all passwords and secure notes.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    SummaryRow(title: "Passwords", value: "\(passwords.count)")
                    SummaryRow(title: "Secure Notes", value: "\(notes.count)")
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))

                InfoWarningCard(
                    kind: .warning,
                    title: "Master password required",
                    message: "This backup will require the Master Password used when it was created to restore later."
                )

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Export failed",
                        message: errorMessage
                    )
                }

                AppButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isEnabled: totalItemCount > 0
                ) {
                    guard totalItemCount > 0 else {
                        errorMessage = "No vault data to export."
                        return
                    }

                    errorMessage = nil
                    isConfirmingMasterPassword = true
                }

                AppButton(
                    title: "Cancel",
                    systemImage: "xmark",
                    kind: .secondary
                ) {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadVaultData()
        }
        .sheet(isPresented: $isConfirmingMasterPassword) {
            MasterPasswordConfirmationView(
                title: "Confirm Master Password",
                message: "Enter your Master Password to export this data."
            ) { masterPassword in
                prepareExport(masterPassword: masterPassword)
            }
        }
        .fileExporter(
            isPresented: $isShowingFileExporter,
            document: exportDocument,
            contentType: .passNoteEncryptedExport,
            defaultFilename: exportFilename
        ) { result in
            if case .failure = result {
                errorMessage = "The vault export could not be saved."
            }
        }
    }

    private func loadVaultData() {
        guard let dbQueue = VaultDatabase.shared.dbQueue else {
            errorMessage = "Database is not open."
            return
        }

        do {
            passwords = try PasswordVaultRepository(dbQueue: dbQueue).fetchPasswords()
            notes = try SecureNotesRepository(dbQueue: dbQueue).fetchNotes()
            errorMessage = totalItemCount == 0 ? "No vault data to export." : nil
        } catch {
            errorMessage = "Could not load vault data for export."
        }
    }

    private func prepareExport(masterPassword: String) -> String? {
        do {
            try ExportSupport.verifyMasterPassword(masterPassword)

            let payload = FullVaultExportPayload(
                passwords: passwords.map(PasswordExportDTO.init),
                notes: notes.map(NoteExportDTO.init)
            )

            let data = try ExportEncryptionService.makeEncryptedExport(
                payload: payload,
                contentType: .fullVault,
                itemCount: totalItemCount,
                masterPassword: masterPassword
            )

            exportDocument = EncryptedExportDocument(
                data: data,
                contentType: .passNoteEncryptedExport
            )
            exportFilename = ExportSupport.vaultBackupFilename()
            isConfirmingMasterPassword = false
            DispatchQueue.main.async {
                isShowingFileExporter = true
            }
            errorMessage = nil
            return nil
        } catch {
            return "Incorrect Master Password or export could not be prepared."
        }
    }
}

private struct SummaryRow: View {
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
