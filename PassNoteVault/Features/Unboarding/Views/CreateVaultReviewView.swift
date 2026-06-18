//
//  CreateVaultReviewView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct CreateVaultReviewView: View {
    @ObservedObject var viewModel: VaultSetupViewModel

    var isCreating: Bool = false
    let onCreateVault: () -> Void

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                StepProgressIndicator(currentStep: 4, totalSteps: 4)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Review vault setup")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Confirm your vault settings before creating the encrypted database.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    ReviewRow(title: "Username", value: viewModel.username)
                    ReviewRow(title: "Password", value: viewModel.isPasswordStrong ? "Strong" : "Weak")
                    ReviewRow(title: "Passphrase", value: viewModel.hasSavedPassphrase ? "Saved" : "Not confirmed")
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))

                Toggle(isOn: $viewModel.enableBiometrics) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Face ID / Touch ID")
                            .font(AppTheme.Typography.callout.weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Text("Use biometrics for faster future unlocks.")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                }
                .toggleStyle(.switch)

                InfoWarningCard(
                    kind: .info,
                    title: "Ready to create vault",
                    message: "Your encrypted database will be created locally on this device."
                )

                AppButton(
                    title: "Create Secure Vault",
                    systemImage: "lock.fill",
                    isEnabled: viewModel.isUsernameValid &&
                        viewModel.canContinueFromPassword &&
                        viewModel.hasSavedPassphrase,
                    isLoading: isCreating,
                    action: onCreateVault
                )
            }
        }
    }
}

private struct ReviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
    }
}