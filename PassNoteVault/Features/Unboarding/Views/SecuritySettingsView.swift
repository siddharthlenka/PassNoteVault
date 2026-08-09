//
//  SecuritySettingsView.swift
//  PassNoteVault
//

import SwiftUI

enum BiometricSettingsAction {
    case enable
    case disable

    var title: String {
        switch self {
        case .enable:
            return "Enable Quick Unlock"
        case .disable:
            return "Disable Quick Unlock"
        }
    }

    var buttonTitle: String {
        switch self {
        case .enable:
            return "Enable"
        case .disable:
            return "Disable"
        }
    }
}

struct SecuritySettingsView: View {
    @AppStorage(BiometricVaultKeyService.isEnabledKey) private var biometricQuickUnlockEnabled = false

    @State private var pendingAction: BiometricSettingsAction?
    @State private var masterPassword = ""
    @State private var errorMessage: String?

    private let biometricService = BiometricVaultKeyService.shared

    private var biometricName: String {
        biometricService.biometricDisplayName
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Security")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Manage quick unlock for this vault.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                biometricSection

                if let errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Security setting failed",
                        message: errorMessage
                    )
                }
            }
        }
        .navigationTitle("Security")
        .sheet(item: $pendingAction) { action in
            masterPasswordPrompt(for: action)
        }
    }

    private var biometricSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                Image(systemName: biometricQuickUnlockEnabled ? "checkmark.shield.fill" : "lock.shield")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("\(biometricName) Quick Unlock")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Use \(biometricName) to unlock Pass & Note without entering your master password every time.")
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            InfoWarningCard(
                kind: .info,
                title: "Master password still required",
                message: "Your master password is required to change security settings and for future sensitive actions. It is never stored for \(biometricName)."
            )

            AppButton(
                title: biometricQuickUnlockEnabled ? "Disable \(biometricName)" : "Enable \(biometricName)",
                systemImage: biometricQuickUnlockEnabled ? "xmark.shield" : "faceid",
                kind: biometricQuickUnlockEnabled ? .secondary : .primary
            ) {
                errorMessage = nil
                masterPassword = ""
                pendingAction = biometricQuickUnlockEnabled ? .disable : .enable
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        }
    }

    private func masterPasswordPrompt(for action: BiometricSettingsAction) -> some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(action.title)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Enter your master password to confirm this security change.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                AppSecureField(
                    title: "Master Password",
                    placeholder: "Enter master password",
                    text: $masterPassword
                )

                HStack(spacing: AppTheme.Spacing.md) {
                    AppButton(
                        title: "Cancel",
                        systemImage: "xmark",
                        kind: .secondary
                    ) {
                        pendingAction = nil
                        masterPassword = ""
                    }

                    AppButton(
                        title: action.buttonTitle,
                        systemImage: action == .enable ? "checkmark.shield" : "xmark.shield"
                    ) {
                        perform(action)
                    }
                }
            }
        }
    }

    private func perform(_ action: BiometricSettingsAction) {
        defer {
            masterPassword = ""
        }

        do {
            var vaultKey = try VaultDatabase.shared.recoverVaultKey(masterPassword: masterPassword)

            defer {
                vaultKey.resetBytes(in: 0..<vaultKey.count)
            }

            switch action {
            case .enable:
                try biometricService.enable(vaultKey: vaultKey)
            case .disable:
                biometricService.disable()
            }

            biometricQuickUnlockEnabled = biometricService.isEnabled
            errorMessage = nil
            pendingAction = nil
        } catch BiometricVaultKeyError.unavailable {
            errorMessage = "\(biometricName) is not available or not enrolled on this device."
            pendingAction = nil
        } catch {
            errorMessage = "The master password could not be verified."
            pendingAction = nil
        }
    }
}

extension BiometricSettingsAction: Identifiable {
    var id: String {
        switch self {
        case .enable:
            return "enable"
        case .disable:
            return "disable"
        }
    }
}
