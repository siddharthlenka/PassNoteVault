//
//  PasswordVaultView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import SwiftUI

struct PasswordVaultView: View {
    @StateObject private var viewModel = PasswordVaultViewModel()

    @State private var isShowingAddPassword = false
    @State private var copiedPasswordId: String?
    @State private var visiblePasswordIds: Set<String> = []
    @State private var entryPendingDelete: PasswordEntry?
    @State private var isShowingPasswordExport = false
    @State private var isShowingPasswordImport = false

    private var isShowingDeleteAlert: Binding<Bool> {
        Binding(
            get: {
                entryPendingDelete != nil
            },
            set: { newValue in
                if !newValue {
                    entryPendingDelete = nil
                }
            }
        )
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                headerSection

                if let errorMessage = viewModel.errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Error",
                        message: errorMessage
                    )
                }

                if let successMessage = viewModel.successMessage {
                    InfoWarningCard(
                        kind: .success,
                        title: "Import complete",
                        message: successMessage
                    )
                }

                if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    passwordTable
                }
            }
        }
        .navigationTitle("Passwords")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isShowingPasswordImport = true
                } label: {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 17, weight: .semibold))
                }

                Button {
                    isShowingPasswordExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                }
                .disabled(viewModel.entries.isEmpty)

                Button {
                    isShowingAddPassword = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $isShowingAddPassword) {
            AddPasswordView { accountName, password in
                viewModel.savePassword(
                    accountName: accountName,
                    password: password
                )
            }
        }
        .sheet(isPresented: $isShowingPasswordExport) {
            PasswordExportView(entries: viewModel.entries)
        }
        .sheet(isPresented: $isShowingPasswordImport) {
            PasswordImportView { importedEntries in
                viewModel.importPasswords(importedEntries)
            }
        }
        .alert("Delete password?", isPresented: isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                entryPendingDelete = nil
            }

            Button("Delete", role: .destructive) {
                if let entry = entryPendingDelete {
                    viewModel.deletePassword(entry)
                    visiblePasswordIds.remove(entry.id)
                    entryPendingDelete = nil
                }
            }
        } message: {
            if let entry = entryPendingDelete {
                Text("This will delete the saved password for \(entry.accountName).")
            } else {
                Text("This saved password will be deleted.")
            }
        }
        .onAppear {
            viewModel.loadPasswords()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Password Vault")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Save account names and passwords locally inside your encrypted vault.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private var emptyState: some View {
        InfoWarningCard(
            kind: .info,
            title: "No passwords yet",
            message: "Tap the plus button on the top right to add your first password."
        )
    }

    private var passwordTable: some View {
        VStack(spacing: 0) {
            tableHeader

            LazyVStack(spacing: 0) {
                ForEach(viewModel.entries) { entry in
                    PasswordEntryRow(
                        entry: entry,
                        isPasswordVisible: visiblePasswordIds.contains(entry.id),
                        isCopied: copiedPasswordId == entry.id,
                        onToggleVisibility: {
                            togglePasswordVisibility(entry)
                        },
                        onCopy: {
                            copyPassword(entry)
                        },
                        onDelete: {
                            entryPendingDelete = entry
                        }
                    )

                    Divider()
                        .background(AppTheme.Colors.border)
                }
            }
        }
        .background(AppTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text("Account")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Password")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("")
                .frame(width: 132)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.elevatedCard)
    }

    private func togglePasswordVisibility(_ entry: PasswordEntry) {
        if visiblePasswordIds.contains(entry.id) {
            visiblePasswordIds.remove(entry.id)
        } else {
            visiblePasswordIds.insert(entry.id)
        }
    }

    private func copyPassword(_ entry: PasswordEntry) {
        ClipboardHelper.copy(entry.password)
        copiedPasswordId = entry.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedPasswordId == entry.id {
                copiedPasswordId = nil
            }
        }
    }
}

private struct PasswordEntryRow: View {
    let entry: PasswordEntry
    let isPasswordVisible: Bool
    let isCopied: Bool

    let onToggleVisibility: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void

    private var displayedPassword: String {
        if isPasswordVisible {
            return entry.password
        } else {
            return String(repeating: "•", count: min(max(entry.password.count, 8), 16))
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(entry.accountName)
                .font(AppTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            passwordText
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Button {
                    onToggleVisibility()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Button {
                    onCopy()
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isCopied ? AppTheme.Colors.success : AppTheme.Colors.accent)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.danger)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 132)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    @ViewBuilder
    private var passwordText: some View {
        if isPasswordVisible {
            Text(displayedPassword)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        } else {
            Text(displayedPassword)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
