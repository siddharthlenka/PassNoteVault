//
//  CreateVaultPassphraseView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct CreateVaultPassphraseView: View {
    @ObservedObject var viewModel: VaultSetupViewModel
    let onContinue: () -> Void

    @State private var didCopy = false

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                StepProgressIndicator(currentStep: 2, totalSteps: 3)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Save your recovery passphrase")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("You need this for first-time login and encrypted backup recovery.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                passphraseCard

                VStack(spacing: AppTheme.Spacing.md) {
                    AppButton(
                        title: didCopy ? "Copied" : "Copy passphrase",
                        systemImage: didCopy ? "checkmark" : "doc.on.doc",
                        kind: .secondary
                    ) {
                        copyToClipboard(viewModel.recoveryPassphrase)
                        didCopy = true
                    }

                    AppButton(
                        title: "Regenerate passphrase",
                        systemImage: "arrow.clockwise",
                        kind: .secondary
                    ) {
                        didCopy = false
                        viewModel.regeneratePassphrase()
                    }
                }

                Toggle(isOn: $viewModel.hasSavedPassphrase) {
                    Text("I saved this passphrase somewhere safe")
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                }
                .toggleStyle(.switch)

                InfoWarningCard(
                    kind: .warning,
                    title: "Cannot be recovered",
                    message: "We cannot recover this passphrase. Keep it safe. It is required to decrypt encrypted backups."
                )

                AppButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isEnabled: viewModel.canContinueFromPassphrase,
                    action: onContinue
                )
            }
        }
    }

    private var passphraseCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)

            Text(viewModel.recoveryPassphrase)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            Text("Write it down or store it somewhere safe.")
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.elevatedCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        }
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
