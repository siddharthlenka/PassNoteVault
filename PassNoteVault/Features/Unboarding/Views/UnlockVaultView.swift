//
//  UnlockVaultView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import SwiftUI

struct UnlockVaultView: View {
    @State private var masterPassword = ""
    @State private var errorMessage: String?

    let successMessage: String?
    var isUnlocking: Bool

    let onUnlock: (_ masterPassword: String) -> String?

    init(
        successMessage: String? = nil,
        isUnlocking: Bool = false,
        onUnlock: @escaping (_ masterPassword: String) -> String?
    ) {
        self.successMessage = successMessage
        self.isUnlocking = isUnlocking
        self.onUnlock = onUnlock
    }

    private var canUnlock: Bool {
        !masterPassword.isEmpty
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Unlock Vault")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Enter your master password to decrypt and open your local vault.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                if let successMessage {
                    InfoWarningCard(
                        kind: .success,
                        title: "Vault created",
                        message: successMessage
                    )
                }

                AppSecureField(
                    title: "Master Password",
                    placeholder: "Enter master password",
                    text: $masterPassword
                )

                InfoWarningCard(
                    kind: .info,
                    title: "Offline unlock",
                    message: "Your vault is decrypted locally on this device. No server or internet connection is used."
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
                        errorMessage = "Please enter your master password."
                        return
                    }

                    if let message = onUnlock(masterPassword) {
                        errorMessage = message
                    } else {
                        errorMessage = nil
                    }
                }
            }
        }
    }
}