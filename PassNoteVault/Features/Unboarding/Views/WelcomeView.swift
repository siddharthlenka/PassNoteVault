//
//  WelcomeView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct WelcomeView: View {
    let onCreateVault: () -> Void
    let onImportBackup: () -> Void

    var body: some View {
        VaultScreenContainer {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer(minLength: AppTheme.Spacing.xl)

                VStack(spacing: AppTheme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accentSoft)
                            .frame(width: 88, height: 88)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.accent)
                    }

                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Your Private Vault")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .multilineTextAlignment(.center)

                    Text("Create a private offline vault for passwords and secure notes. No cloud. No account. No tracking.")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    InfoWarningCard(
                        kind: .info,
                        title: "Offline by design",
                        message: "Your vault stays on this device. No internet connection or server account is required."
                    )

                    AppButton(
                        title: "Create New Vault",
                        systemImage: "plus.circle.fill",
                        kind: .primary,
                        action: onCreateVault
                    )

                    AppButton(
                        title: "Restore From Backup",
                        systemImage: "tray.and.arrow.down",
                        kind: .secondary,
                        action: onImportBackup
                    )
                }

                Spacer(minLength: AppTheme.Spacing.xl)
            }
        }
    }
}
