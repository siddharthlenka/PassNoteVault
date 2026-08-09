//
//  PrivateVaultApp.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct VaultRootView: View {
    @AppStorage(VaultLifecycleMetadata.hasCreatedVaultKey) private var hasCreatedVault = false
    @AppStorage(VaultLifecycleMetadata.vaultHasBeenActivatedKey) private var vaultHasBeenActivated = true
    @AppStorage(VaultLifecycleMetadata.activationMetadataInitializedKey) private var activationMetadataInitialized = false
    @AppStorage(BiometricVaultKeyService.isEnabledKey) private var biometricQuickUnlockEnabled = false

    @State private var isUnlocked = false
    @State private var unlockSuccessMessage: String?
    @State private var unlockSessionID = UUID()
    @State private var isShowingUnusedVaultRestore = false

    private var canStartOverUnusedVault: Bool {
        hasCreatedVault && activationMetadataInitialized && !vaultHasBeenActivated
    }

    var body: some View {
        if isUnlocked {
            VaultLandingView(
                onLockVault: {
                    VaultDatabase.shared.close()
                    unlockSessionID = UUID()
                    isUnlocked = false
                }
            )
        } else if !hasCreatedVault {
            VaultOnboardingCoordinator(
                onVaultCreated: {
                    hasCreatedVault = true
                    unlockSessionID = UUID()
                    unlockSuccessMessage = """
                    Vault created successfully. Enter your master password to unlock your vault.
                    """
                },
                onVaultRestored: {
                    hasCreatedVault = true
                    vaultHasBeenActivated = true
                    unlockSuccessMessage = nil
                    unlockSessionID = UUID()
                    isUnlocked = true
                }
            )
        } else {
            UnlockVaultView(
                successMessage: unlockSuccessMessage,
                canStartOver: canStartOverUnusedVault,
                onUnlock: { masterPassword in
                    do {
                        try VaultDatabase.shared.open(masterPassword: masterPassword)
                        completeSuccessfulVaultUnlock()
                        return nil
                    } catch {
                        print("Unlock failed:", error)
                        return "Invalid master password or vault could not be opened."
                    }
                },
                onBiometricUnlock: {
                    await unlockWithBiometrics()
                },
                onDisableBiometric: { masterPassword in
                    disableBiometrics(masterPassword: masterPassword)
                },
                onStartOver: {
                    do {
                        try VaultDatabase.shared.resetUnusedVault()
                        hasCreatedVault = false
                        unlockSessionID = UUID()
                        unlockSuccessMessage = nil
                        return nil
                    } catch {
                        print("Start over failed:", error)
                        return "Could not start over. Please try again."
                    }
                },
                onRestoreFromBackup: {
                    isShowingUnusedVaultRestore = true
                }
            )
            .id(unlockSessionID)
            .sheet(isPresented: $isShowingUnusedVaultRestore) {
                FullVaultRestoreView(resetUnusedVaultBeforeRestore: true) {
                    hasCreatedVault = true
                    vaultHasBeenActivated = true
                    unlockSuccessMessage = nil
                    unlockSessionID = UUID()
                    isUnlocked = true
                }
            }
        }
    }

    @MainActor
    private func unlockWithBiometrics() async -> String? {
        do {
            var vaultKey = try await BiometricVaultKeyService.shared.unlockVaultKey(
                reason: "Unlock Pass & Note"
            )

            defer {
                vaultKey.resetBytes(in: 0..<vaultKey.count)
            }

            try openVault(using: vaultKey)
            return nil
        } catch {
            biometricQuickUnlockEnabled = BiometricVaultKeyService.shared.isEnabled
            return "Biometric unlock failed. Enter your Master Password to unlock the vault."
        }
    }

    @MainActor
    private func openVault(using vaultKey: Data) throws {
        try VaultDatabase.shared.open(vaultKey: vaultKey)
        completeSuccessfulVaultUnlock()
    }

    @MainActor
    private func completeSuccessfulVaultUnlock() {
        VaultLifecycleMetadata.markVaultActivated()
        unlockSuccessMessage = nil
        unlockSessionID = UUID()
        isUnlocked = true
    }

    private func disableBiometrics(masterPassword: String) -> String? {
        do {
            var vaultKey = try VaultDatabase.shared.recoverVaultKey(masterPassword: masterPassword)

            defer {
                vaultKey.resetBytes(in: 0..<vaultKey.count)
            }

            BiometricVaultKeyService.shared.disable()
            biometricQuickUnlockEnabled = false
            return nil
        } catch {
            return "The master password could not be verified. Biometric unlock is still enabled."
        }
    }
}
