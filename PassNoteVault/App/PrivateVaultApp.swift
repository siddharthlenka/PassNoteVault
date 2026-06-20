//
//  PrivateVaultApp.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct VaultRootView: View {
    @AppStorage("hasCreatedVault") private var hasCreatedVault = false

    @State private var isUnlocked = false
    @State private var unlockSuccessMessage: String?

    var body: some View {
        if isUnlocked {
            VaultLandingView(
                onLockVault: {
                    VaultDatabase.shared.close()
                    isUnlocked = false
                }
            )
        } else if !hasCreatedVault {
            VaultOnboardingCoordinator {
                hasCreatedVault = true
                unlockSuccessMessage = """
                Vault created successfully. Enter your master password to unlock your vault.
                """
            }
        } else {
            UnlockVaultView(
                successMessage: unlockSuccessMessage
            ) { masterPassword in
                do {
                    try VaultDatabase.shared.open(passphrase: masterPassword)
                    unlockSuccessMessage = nil
                    isUnlocked = true
                    return nil
                } catch {
                    print("Unlock failed:", error)
                    return "Invalid master password or vault could not be opened."
                }
            }
        }
    }
}
