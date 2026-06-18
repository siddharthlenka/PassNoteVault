//
//  FirstTimeLoginView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct FirstTimeLoginView: View {
    @State private var username = ""
    @State private var masterPassword = ""
    @State private var passphrase = ""
    @State private var errorMessage: String?

    var isUnlocking: Bool = false

    let onUnlock: (_ username: String, _ password: String, _ passphrase: String) -> Void

    private var canUnlock: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !masterPassword.isEmpty &&
        !passphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Unlock your vault")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("For the first unlock, enter your username, master password, and recovery passphrase.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    AppTextField(
                        title: "Username",
                        placeholder: "Enter username",
                        text: $username
                    )

                    AppSecureField(
                        title: "Master password",
                        placeholder: "Enter master password",
                        text: $masterPassword
                    )

                    AppSecureField(
                        title: "Recovery passphrase",
                        placeholder: "Enter passphrase",
                        text: $passphrase
                    )
                }

                InfoWarningCard(
                    kind: .info,
                    title: "First unlock only",
                    message: "Your passphrase is required for first-time login and later for encrypted backup recovery."
                )

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Unlock failed",
                        message: errorMessage
                    )
                }

                AppButton(
                    title: "Unlock Vault",
                    systemImage: "lock.open.fill",
                    isEnabled: canUnlock,
                    isLoading: isUnlocking
                ) {
                    guard canUnlock else {
                        errorMessage = "Please enter all required fields."
                        return
                    }

                    errorMessage = nil
                    onUnlock(username, masterPassword, passphrase)
                }
            }
        }
    }
}