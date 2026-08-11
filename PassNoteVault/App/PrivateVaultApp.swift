//
//  PrivateVaultApp.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI
import UIKit

struct VaultRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(VaultLifecycleMetadata.hasCreatedVaultKey) private var hasCreatedVault = false
    @AppStorage(VaultLifecycleMetadata.vaultHasBeenActivatedKey) private var vaultHasBeenActivated = true
    @AppStorage(VaultLifecycleMetadata.activationMetadataInitializedKey) private var activationMetadataInitialized = false
    @AppStorage(BiometricVaultKeyService.isEnabledKey) private var biometricQuickUnlockEnabled = false

    @State private var isUnlocked = false
    @State private var unlockSuccessMessage: String?
    @State private var unlockSessionID = UUID()
    @State private var isShowingUnusedVaultRestore = false
    @State private var isShowingPrivacyShield = false
    @State private var isAuthenticatingForegroundUnlock = false
    @State private var didEnterBackgroundSinceShield = false

    private var canStartOverUnusedVault: Bool {
        hasCreatedVault && activationMetadataInitialized && !vaultHasBeenActivated
    }

    var body: some View {
        ZStack {
            rootContent

            if isShowingPrivacyShield {
                PrivacyShieldView()
                    .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)) { _ in
            guard scenePhase == .active else {
                return
            }

            handleReturnToForeground()
        }
    }

    @ViewBuilder
    private var rootContent: some View {
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
                reason: "Unlock Pass&Note Vault"
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

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            handleReturnToForeground()

        case .inactive:
            guard isUnlocked else {
                return
            }

            NotificationCenter.default.post(name: .passNoteShouldAutosaveSensitiveEditors, object: nil)
            isShowingPrivacyShield = true

        case .background:
            guard isUnlocked else {
                return
            }

            NotificationCenter.default.post(name: .passNoteShouldAutosaveSensitiveEditors, object: nil)
            ClipboardHelper.clearCopiedPasswordWhenBackgrounded()
            VaultSettingsMetadata.recordBackgroundDate()
            didEnterBackgroundSinceShield = true
            isShowingPrivacyShield = true

        @unknown default:
            break
        }
    }

    private func handleReturnToForeground() {
        guard isUnlocked, isShowingPrivacyShield else {
            isShowingPrivacyShield = false
            didEnterBackgroundSinceShield = false
            return
        }

        guard didEnterBackgroundSinceShield else {
            isShowingPrivacyShield = false
            return
        }

        guard UIApplication.shared.isProtectedDataAvailable else {
            return
        }

        let duration = VaultSettingsMetadata.autoLockDuration
        let elapsed = VaultSettingsMetadata.lastBackgroundDate.map { Date().timeIntervalSince($0) } ?? 0

        guard elapsed >= duration.threshold else {
            isShowingPrivacyShield = false
            didEnterBackgroundSinceShield = false
            return
        }

        guard biometricQuickUnlockEnabled && BiometricVaultKeyService.shared.isEnabled else {
            lockVaultForMasterPassword()
            return
        }

        authenticateForegroundUnlock()
    }

    private func authenticateForegroundUnlock() {
        guard !isAuthenticatingForegroundUnlock else {
            return
        }

        isAuthenticatingForegroundUnlock = true

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let message = await unlockWithBiometrics()

            await MainActor.run {
                isAuthenticatingForegroundUnlock = false

                if message == nil {
                    isShowingPrivacyShield = false
                    didEnterBackgroundSinceShield = false
                } else {
                    lockVaultForMasterPassword()
                }
            }
        }
    }

    private func lockVaultForMasterPassword() {
        VaultDatabase.shared.close()
        unlockSessionID = UUID()
        unlockSuccessMessage = nil
        isUnlocked = false
        isShowingPrivacyShield = false
        didEnterBackgroundSinceShield = false
    }
}
