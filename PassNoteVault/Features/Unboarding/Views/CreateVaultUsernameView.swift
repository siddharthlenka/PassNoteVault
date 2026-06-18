//
//  CreateVaultUsernameView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct CreateVaultUsernameView: View {
    @ObservedObject var viewModel: VaultSetupViewModel
    let onContinue: () -> Void

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                StepProgressIndicator(currentStep: 1, totalSteps: 4)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Create your vault")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Choose a local username to identify this vault on your device.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                AppTextField(
                    title: "Username",
                    placeholder: "Enter local username",
                    text: $viewModel.username,
                    error: viewModel.username.isEmpty ? nil : viewModel.usernameError
                )

                InfoWarningCard(
                    kind: .info,
                    title: "Local only",
                    message: "This username is stored only on this device. We do not create an online account."
                )

                AppButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isEnabled: viewModel.isUsernameValid,
                    action: onContinue
                )
            }
        }
    }
}