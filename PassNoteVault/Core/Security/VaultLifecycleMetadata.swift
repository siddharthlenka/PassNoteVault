//
//  VaultLifecycleMetadata.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 08/08/26.
//

import Foundation

enum VaultLifecycleMetadata {
    static let hasCreatedVaultKey = "hasCreatedVault"
    static let vaultHasBeenActivatedKey = "vaultHasBeenActivated"
    static let activationMetadataInitializedKey = "vaultActivationMetadataInitialized"

    static var hasCreatedVault: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCreatedVaultKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCreatedVaultKey)
        }
    }

    static var vaultHasBeenActivated: Bool {
        get {
            guard activationMetadataInitialized else {
                return true
            }

            return UserDefaults.standard.bool(forKey: vaultHasBeenActivatedKey)
        }
        set {
            UserDefaults.standard.set(true, forKey: activationMetadataInitializedKey)
            UserDefaults.standard.set(newValue, forKey: vaultHasBeenActivatedKey)
        }
    }

    static var canResetUnusedVault: Bool {
        hasCreatedVault && activationMetadataInitialized && !vaultHasBeenActivated
    }

    static func prepareNewVaultLifecycle() {
        UserDefaults.standard.set(true, forKey: activationMetadataInitializedKey)
        UserDefaults.standard.set(false, forKey: vaultHasBeenActivatedKey)
    }

    static func markVaultActivated() {
        vaultHasBeenActivated = true
    }

    static func clearUnusedVaultLifecycle() {
        UserDefaults.standard.set(false, forKey: hasCreatedVaultKey)
        UserDefaults.standard.set(false, forKey: vaultHasBeenActivatedKey)
        UserDefaults.standard.set(false, forKey: activationMetadataInitializedKey)
    }

    private static var activationMetadataInitialized: Bool {
        UserDefaults.standard.bool(forKey: activationMetadataInitializedKey)
    }
}
