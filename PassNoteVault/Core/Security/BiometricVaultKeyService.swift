//
//  BiometricVaultKeyService.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 08/08/26.
//

import Foundation
import LocalAuthentication
import Security

enum BiometricVaultKeyError: Error {
    case unavailable
    case userCancelled
    case authenticationFailed
    case lockedOut
    case itemMissingOrInvalid
    case keychainFailure(OSStatus)
    case invalidVaultKeyLength
    case accessControlUnavailable
}

final class BiometricVaultKeyService {
    static let shared = BiometricVaultKeyService()

    static let isEnabledKey = "biometricQuickUnlockEnabled"

    private let service = "com.passnotevault.security"
    private let account = "biometric-vault-key-v1"

    private init() {}

    var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: Self.isEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.isEnabledKey)
        }
    }

    var biometricDisplayName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometrics"
        }
    }

    func canUseBiometrics() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func enable(vaultKey: Data) throws {
        guard vaultKey.count == VaultKeyEnvelope.vaultKeyByteCount else {
            throw BiometricVaultKeyError.invalidVaultKeyLength
        }

        guard canUseBiometrics() else {
            throw BiometricVaultKeyError.unavailable
        }

        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )

        guard let accessControl else {
            throw BiometricVaultKeyError.accessControlUnavailable
        }

        deleteStoredVaultKey()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessControl as String: accessControl,
            kSecValueData as String: vaultKey
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            isEnabled = false
            throw BiometricVaultKeyError.keychainFailure(status)
        }

        isEnabled = true
    }

    func disable() {
        deleteStoredVaultKey()
        isEnabled = false
    }

    func unlockVaultKey(reason: String) async throws -> Data {
        guard isEnabled else {
            throw BiometricVaultKeyError.unavailable
        }

        let context = LAContext()
        context.localizedReason = reason
        context.localizedFallbackTitle = ""

        do {
            try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            throw mapAuthenticationError(error)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound || status == errSecAuthFailed {
                isEnabled = false
                throw BiometricVaultKeyError.itemMissingOrInvalid
            }

            throw BiometricVaultKeyError.keychainFailure(status)
        }

        guard let vaultKey = result as? Data,
              vaultKey.count == VaultKeyEnvelope.vaultKeyByteCount else {
            isEnabled = false
            throw BiometricVaultKeyError.invalidVaultKeyLength
        }

        return vaultKey
    }

    private func deleteStoredVaultKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }

    private func mapAuthenticationError(_ error: Error) -> BiometricVaultKeyError {
        let nsError = error as NSError
        guard nsError.domain == LAError.errorDomain,
              let code = LAError.Code(rawValue: nsError.code) else {
            return .authenticationFailed
        }

        switch code {
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
            isEnabled = false
            return .unavailable
        case .userCancel, .systemCancel, .appCancel:
            return .userCancelled
        case .biometryLockout:
            return .lockedOut
        default:
            return .authenticationFailed
        }
    }
}
