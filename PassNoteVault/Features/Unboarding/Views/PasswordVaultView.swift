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
    @State private var copiedPasswordId: UUID?

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

                if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    passwordTable
                }
            }
        }
        .navigationTitle("Passwords")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        .onAppear {
            viewModel.loadPasswords()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Password Vault")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Save account names and passwords locally inside your vault.")
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
                        isCopied: copiedPasswordId == entry.id
                    ) {
                        ClipboardHelper.copy(entry.password)
                        copiedPasswordId = entry.id

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            if copiedPasswordId == entry.id {
                                copiedPasswordId = nil
                            }
                        }
                    }

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
                .frame(width: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.elevatedCard)
    }
}

private struct PasswordEntryRow: View {
    let entry: PasswordEntry
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(entry.accountName)
                .font(AppTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.password)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onCopy()
            } label: {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isCopied ? AppTheme.Colors.success : AppTheme.Colors.accent)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}