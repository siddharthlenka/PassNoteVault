//
//  FirstTimeLoginView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct FirstTimeLoginView: View {
    @State private var username: String
    @State private var masterPassword = ""
    @State private var errorMessage: String?

    let successMessage: String?
    var isUnlocking: Bool

    let onUnlock: (_ username: String, _ password: String) -> String?

    init(
        initialUsername: String = "",
        successMessage: String? = nil,
        isUnlocking: Bool = false,
        onUnlock: @escaping (_ username: String, _ password: String) -> String?
    ) {
        self._username = State(initialValue: initialUsername)
        self.successMessage = successMessage
        self.isUnlocking = isUnlocking
        self.onUnlock = onUnlock
    }

    private var canUnlock: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !masterPassword.isEmpty
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Login to your vault")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Enter your local username and master password to unlock this device vault.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                if let successMessage {
                    InfoWarningCard(
                        kind: .success,
                        title: "Account created",
                        message: successMessage
                    )
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
                }

                InfoWarningCard(
                    kind: .info,
                    title: "Local unlock",
                    message: "Your credentials are checked locally on this device. No server or internet connection is used."
                )

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Login failed",
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
                        errorMessage = "Please enter username and password."
                        return
                    }

                    let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

                    if let message = onUnlock(trimmedUsername, masterPassword) {
                        errorMessage = message
                    } else {
                        errorMessage = nil
                    }
                }
            }
        }
    }
}
