//
//  PrivateVaultApp.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI



struct VaultRootView: View {
    @AppStorage("hasCreatedVault") private var hasCreatedVault = false
    @AppStorage("hasCompletedFirstUnlock") private var hasCompletedFirstUnlock = false

    var body: some View {
        if !hasCreatedVault {
            VaultOnboardingCoordinator()
        } else if !hasCompletedFirstUnlock {
            FirstTimeLoginView { username, password, passphrase in
                // TODO: open encrypted SQLCipher database
                hasCompletedFirstUnlock = true
            }
        } else {
//            NormalUnlockView(
//                username: "Sid",
//                onBiometricUnlock: {
//                    // TODO: biometric unlock
//                },
//                onUsePassword: {
//                    // TODO: show password unlock screen
//                }
//            )
        }
    }
}
