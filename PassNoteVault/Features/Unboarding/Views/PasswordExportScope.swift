//
//  PasswordExportScope.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import SwiftUI

enum PasswordExportScope: String, CaseIterable, Identifiable {
    case all
    case selected

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all:
            return "Export All"
        case .selected:
            return "Choose Passwords"
        }
    }
}

struct PasswordExportView: View {
    @Environment(\.dismiss) private var dismiss

    let entries: [PasswordEntry]

    @State private var exportScope: PasswordExportScope = .all
    @State private var selectedIDs: Set<String> = []
    @State private var isConfirmingMasterPassword = false
    @State private var errorMessage: String?
    @State private var exportDocument = EncryptedExportDocument(
        data: Data(),
        contentType: .passNoteEncryptedExport
    )
    @State private var exportFilename = ExportSupport.passwordFilename()
    @State private var isShowingFileExporter = false

    private var selectedEntries: [PasswordEntry] {
        switch exportScope {
        case .all:
            return entries
        case .selected:
            return entries.filter { selectedIDs.contains($0.id) }
        }
    }

    private var exportCount: Int {
        selectedEntries.count
    }

    private var isEveryPasswordSelected: Bool {
        !entries.isEmpty && selectedIDs.count == entries.count
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    headerSection

                    Picker("Export scope", selection: $exportScope) {
                        ForEach(PasswordExportScope.allCases) { scope in
                            Text(scope.title)
                                .tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)

                    InfoWarningCard(
                        kind: .warning,
                        title: "Encrypted export only",
                        message: "Passwords can be exported only as an encrypted backup. Your master password is required before export."
                    )

                    if let errorMessage {
                        InfoWarningCard(
                            kind: .warning,
                            title: "Export failed",
                            message: errorMessage
                        )
                    }

                    if exportScope == .selected {
                        selectedPasswordList
                    }

                    InfoWarningCard(
                        kind: .info,
                        title: "Export preview",
                        message: "\(exportCount) password item(s) selected for encrypted export."
                    )

                    buttonSection
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: AppTheme.Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
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
            if case .success = result {
                dismiss()
            } else {
                errorMessage = "The password export could not be saved."
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Export Passwords")
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Create one encrypted password package for the selected records.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private var selectedPasswordList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Button {
                toggleSelectAll()
            } label: {
                Label(
                    isEveryPasswordSelected ? "Deselect All" : "Select All",
                    systemImage: isEveryPasswordSelected ? "minus.circle" : "checkmark.circle"
                )
                .font(AppTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.accent)
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                ForEach(entries) { entry in
                    Toggle(isOn: selectionBinding(for: entry)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.accountName)
                                .font(AppTheme.Typography.callout.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            Text(passwordExportSubtitle(for: entry))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(AppTheme.Spacing.md)

                    Divider()
                        .background(AppTheme.Colors.border)
                }
            }
            .background(AppTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            }
        }
    }

    private var buttonSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AppButton(
                title: "Export \(exportCount)",
                systemImage: "lock.doc",
                isEnabled: exportCount > 0
            ) {
                guard exportCount > 0 else {
                    errorMessage = "Select at least one password to export."
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

    private func selectionBinding(for entry: PasswordEntry) -> Binding<Bool> {
        Binding(
            get: {
                selectedIDs.contains(entry.id)
            },
            set: { isSelected in
                if isSelected {
                    selectedIDs.insert(entry.id)
                } else {
                    selectedIDs.remove(entry.id)
                }
            }
        )
    }

    private func toggleSelectAll() {
        if isEveryPasswordSelected {
            selectedIDs.removeAll()
        } else {
            selectedIDs = Set(entries.map(\.id))
        }
    }

    private func passwordExportSubtitle(for entry: PasswordEntry) -> String {
        guard let username = entry.username, !username.isEmpty else {
            return "Password will be included in encrypted export"
        }

        return username
    }

    private func prepareExport(masterPassword: String) -> String? {
        do {
            try ExportSupport.verifyMasterPassword(masterPassword)

            let payload = PasswordExportPayload(
                passwords: selectedEntries.map(PasswordExportDTO.init)
            )

            let data = try ExportEncryptionService.makeEncryptedExport(
                payload: payload,
                contentType: .passwords,
                itemCount: selectedEntries.count,
                masterPassword: masterPassword
            )

            exportDocument = EncryptedExportDocument(
                data: data,
                contentType: .passNoteEncryptedExport
            )
            exportFilename = ExportSupport.passwordFilename()
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
