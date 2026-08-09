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

    private var exportCount: Int {
        switch exportScope {
        case .all:
            return entries.count
        case .selected:
            return selectedIDs.count
        }
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
                        message: "Passwords can be exported only as an encrypted backup. Remember your master password. You will need it to reuse or import your passwords later."
                    )

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
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Export Passwords")
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Export your saved passwords as an encrypted backup file.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private var selectedPasswordList: some View {
        VStack(spacing: 0) {
            ForEach(entries) { entry in
                Toggle(isOn: selectionBinding(for: entry)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.accountName)
                            .font(AppTheme.Typography.callout.weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Text("Password will be included in encrypted export")
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

    private var buttonSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AppButton(
                title: "Export Encrypted Backup",
                systemImage: "lock.doc",
                isEnabled: exportCount > 0
            ) {
                // TODO later:
                // 1. Collect selected passwords
                // 2. Convert to backup JSON
                // 3. Encrypt using master password
                // 4. Show share sheet
                dismiss()
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
}