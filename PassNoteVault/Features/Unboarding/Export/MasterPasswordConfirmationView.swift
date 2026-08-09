//
//  MasterPasswordConfirmationView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//
//  Created by siddharth lenka on 20/06/26.
//

import SwiftUI

struct MasterPasswordConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let message: String
    var passwordTitle: String = "Master Password"
    var passwordPlaceholder: String = "Enter master password"
    let onConfirm: (_ masterPassword: String) -> String?

    @State private var masterPassword = ""
    @State private var errorMessage: String?
    @FocusState private var isPasswordFocused: Bool

    private var canContinue: Bool {
        !masterPassword.isEmpty
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(title)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text(message)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                AppSecureField(
                    title: passwordTitle,
                    placeholder: passwordPlaceholder,
                    text: $masterPassword,
                    error: errorMessage,
                    focus: $isPasswordFocused
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    AppButton(
                        title: "Cancel",
                        systemImage: "xmark",
                        kind: .secondary
                    ) {
                        masterPassword = ""
                        dismiss()
                    }

                    AppButton(
                        title: "Continue",
                        systemImage: "arrow.right",
                        isEnabled: canContinue
                    ) {
                        confirm()
                    }
                }
            }
        }
        .onAppear {
            isPasswordFocused = true
        }
    }

    private func confirm() {
        guard canContinue else {
            errorMessage = "Enter your master password."
            isPasswordFocused = true
            return
        }

        if let message = onConfirm(masterPassword) {
            errorMessage = message
            masterPassword = ""
            isPasswordFocused = true
        } else {
            masterPassword = ""
            dismiss()
        }
    }
}
