//
//  CreateVaultPasswordView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct CreateVaultPasswordView: View {
    @ObservedObject var viewModel: VaultSetupViewModel
    let onContinue: () -> Void

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                StepProgressIndicator(currentStep: 1, totalSteps: 2)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Create a strong password")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("This password protects your encrypted vault.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    AppSecureField(
                        title: "Master password",
                        placeholder: "Enter master password",
                        text: $viewModel.masterPassword
                    )

                    AppSecureField(
                        title: "Confirm password",
                        placeholder: "Re-enter master password",
                        text: $viewModel.confirmPassword,
                        error: viewModel.passwordMatchError
                    )
                }

                PasswordChecklist(result: viewModel.passwordValidation)

                InfoWarningCard(
                    kind: .warning,
                    title: "Recovery warning",
                    message: "If you forget your password, your vault cannot be recovered."
                )

                AppButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isEnabled: viewModel.canContinueFromPassword,
                    action: onContinue
                )
            }
        }
    }
}

private struct PasswordChecklist: View {
    let result: PasswordValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Password strength")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                RuleRow(title: "At least 12 characters", isValid: result.hasMinimumLength)
                RuleRow(title: "Uppercase letter", isValid: result.hasUppercase)
                RuleRow(title: "Lowercase letter", isValid: result.hasLowercase)
                RuleRow(title: "Number", isValid: result.hasNumber)
                RuleRow(title: "Special character", isValid: result.hasSpecialCharacter)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        }
    }
}

private struct RuleRow: View {
    let title: String
    let isValid: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isValid ? AppTheme.Colors.success : AppTheme.Colors.mutedText)

            Text(title)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(isValid ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)

            Spacer()
        }
    }
}
