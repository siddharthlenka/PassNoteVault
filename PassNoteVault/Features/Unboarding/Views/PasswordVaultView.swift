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
    @State private var isShowingPasswordExport = false
    @State private var isShowingPasswordImport = false
    @State private var isSelectingPasswords = false
    @State private var selectedPasswordIds: Set<String> = []
    @State private var isShowingDeleteSelectedAlert = false

    private var selectedEntries: [PasswordEntry] {
        viewModel.entries.filter { selectedPasswordIds.contains($0.id) }
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
                if !viewModel.entries.isEmpty {
                    Button(isSelectingPasswords ? "Cancel" : "Select") {
                        if isSelectingPasswords {
                            exitSelectionMode()
                        } else {
                            isSelectingPasswords = true
                        }
                    }

                    if isSelectingPasswords {
                        Button {
                            isShowingDeleteSelectedAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .disabled(selectedPasswordIds.isEmpty)
                    }
                }

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
                .disabled(isSelectingPasswords)

                Button {
                    isShowingAddPassword = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                }
                .disabled(isSelectingPasswords)
            }
        }
        .sheet(isPresented: $isShowingAddPassword) {
            AddPasswordView { accountName, username, password in
                viewModel.savePassword(
                    accountName: accountName,
                    username: username,
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
        .alert("Delete selected passwords?", isPresented: $isShowingDeleteSelectedAlert) {
            Button("Cancel", role: .cancel) {
                isShowingDeleteSelectedAlert = false
            }

            Button("Delete", role: .destructive) {
                deleteSelectedPasswords()
            }
        } message: {
            Text("This will delete \(selectedPasswordIds.count) selected password \(selectedPasswordIds.count == 1 ? "record" : "records").")
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
                        isSelecting: isSelectingPasswords,
                        isSelected: selectedPasswordIds.contains(entry.id),
                        onToggleSelection: {
                            toggleSelection(entry)
                        },
                        onToggleVisibility: {
                            togglePasswordVisibility(entry)
                        },
                        onCopy: {
                            copyPassword(entry)
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
            if isSelectingPasswords {
                Text("")
                    .frame(width: 28)
            }

            Text("Account")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Password")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("")
                .frame(width: 88)
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

    private func toggleSelection(_ entry: PasswordEntry) {
        if selectedPasswordIds.contains(entry.id) {
            selectedPasswordIds.remove(entry.id)
        } else {
            selectedPasswordIds.insert(entry.id)
        }
    }

    private func deleteSelectedPasswords() {
        let idsToDelete = selectedPasswordIds
        visiblePasswordIds.subtract(idsToDelete)
        viewModel.deletePasswords(selectedEntries)
        exitSelectionMode()
    }

    private func exitSelectionMode() {
        isSelectingPasswords = false
        selectedPasswordIds.removeAll()
    }
}

private struct PasswordEntryRow: View {
    let entry: PasswordEntry
    let isPasswordVisible: Bool
    let isCopied: Bool
    let isSelecting: Bool
    let isSelected: Bool

    let onToggleSelection: () -> Void
    let onToggleVisibility: () -> Void
    let onCopy: () -> Void

    private var displayedPassword: String {
        if isPasswordVisible {
            return entry.password
        } else {
            return String(repeating: "•", count: min(max(entry.password.count, 8), 16))
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if isSelecting {
                Button {
                    onToggleSelection()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.mutedText)
                        .frame(width: 28, height: 44)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.accountName)
                    .font(AppTheme.Typography.callout.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                if let username = entry.username, !username.isEmpty {
                    Text(username)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            passwordText
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

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
            }
            .frame(width: 88)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                onToggleSelection()
            }
        }
    }

    @ViewBuilder
    private var passwordText: some View {
        if isPasswordVisible {
            Text(displayedPassword)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineLimit(nil)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(displayedPassword)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineLimit(nil)
                .truncationMode(.middle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
