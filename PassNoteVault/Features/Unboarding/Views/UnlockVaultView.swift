//
//  UnlockVaultView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import SwiftUI

struct UnlockVaultView: View {
    @AppStorage(BiometricVaultKeyService.isEnabledKey) private var biometricQuickUnlockEnabled = false

    @State private var masterPassword = ""
    @State private var errorMessage: String?
    @State private var isShowingStartOverConfirmation = false
    @State private var isShowingDisableBiometricConfirmation = false
    @State private var isUsingMasterPasswordFallback = false
    @State private var isAuthenticatingBiometric = false
    @FocusState private var isMasterPasswordFocused: Bool

    let successMessage: String?
    var isUnlocking: Bool
    let canStartOver: Bool

    let onUnlock: (_ masterPassword: String) -> String?
    let onBiometricUnlock: () async -> String?
    let onDisableBiometric: (_ masterPassword: String) -> String?
    let onStartOver: () -> String?

    private let biometricService = BiometricVaultKeyService.shared

    init(
        successMessage: String? = nil,
        isUnlocking: Bool = false,
        canStartOver: Bool = false,
        onUnlock: @escaping (_ masterPassword: String) -> String?,
        onBiometricUnlock: @escaping () async -> String? = { nil },
        onDisableBiometric: @escaping (_ masterPassword: String) -> String? = { _ in nil },
        onStartOver: @escaping () -> String? = { nil }
    ) {
        self.successMessage = successMessage
        self.isUnlocking = isUnlocking
        self.canStartOver = canStartOver
        self.onUnlock = onUnlock
        self.onBiometricUnlock = onBiometricUnlock
        self.onDisableBiometric = onDisableBiometric
        self.onStartOver = onStartOver
    }

    private var biometricName: String {
        biometricService.biometricDisplayName
    }

    private var canUnlock: Bool {
        if biometricQuickUnlockEnabled && !isUsingMasterPasswordFallback {
            return true
        }

        return !masterPassword.isEmpty
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
                    text: $masterPassword,
                    focus: $isMasterPasswordFocused
                )

                if biometricQuickUnlockEnabled {
                    biometricStatusRow
                }

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
                    isLoading: isUnlocking || isAuthenticatingBiometric
                ) {
                    unlockVault()
                }

                if canStartOver {
                    startOverSection
                }
            }
        }
        .alert("Create a New Vault?", isPresented: $isShowingStartOverConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Start Over", role: .destructive) {
                if let message = onStartOver() {
                    errorMessage = message
                } else {
                    errorMessage = nil
                }
            }
        } message: {
            Text("This vault has not been used yet. Starting over will remove the current vault setup and let you create a new master password.")
        }
        .alert("Disable \(biometricName)?", isPresented: $isShowingDisableBiometricConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disable", role: .destructive) {
                disableBiometricUnlock()
            }
        } message: {
            Text("Enter your master password first, then disable \(biometricName) quick unlock.")
        }
    }

    private var biometricStatusRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(biometricName) Unlock")
                    .font(AppTheme.Typography.callout.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text("Enabled")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { biometricQuickUnlockEnabled },
                set: { isEnabled in
                    guard !isEnabled else { return }
                    isShowingDisableBiometricConfirmation = true
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        }
    }

    private var startOverSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Having trouble with the password you just created?")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            AppButton(
                title: "Start Over",
                systemImage: "arrow.counterclockwise",
                kind: .secondary
            ) {
                isShowingStartOverConfirmation = true
            }
        }
    }

    private func unlockVault() {
        if biometricQuickUnlockEnabled && !isUsingMasterPasswordFallback {
            authenticateWithBiometrics()
            return
        }

        unlockWithMasterPassword()
    }

    private func authenticateWithBiometrics() {
        isAuthenticatingBiometric = true
        errorMessage = nil

        Task {
            let message = await onBiometricUnlock()

            await MainActor.run {
                isAuthenticatingBiometric = false

                if let message {
                    isUsingMasterPasswordFallback = true
                    errorMessage = message
                    isMasterPasswordFocused = true
                } else {
                    errorMessage = nil
                }
            }
        }
    }

    private func unlockWithMasterPassword() {
        guard !masterPassword.isEmpty else {
            errorMessage = "Please enter your master password."
            isMasterPasswordFocused = true
            return
        }

        if let message = onUnlock(masterPassword) {
            errorMessage = message
            isMasterPasswordFocused = true
        } else {
            isUsingMasterPasswordFallback = false
            masterPassword = ""
            errorMessage = nil
            isMasterPasswordFocused = false
        }
    }

    private func disableBiometricUnlock() {
        guard !masterPassword.isEmpty else {
            errorMessage = "Enter your master password to disable \(biometricName) quick unlock."
            isMasterPasswordFocused = true
            return
        }

        if let message = onDisableBiometric(masterPassword) {
            errorMessage = message
            isMasterPasswordFocused = true
        } else {
            errorMessage = nil
        }
    }
}
