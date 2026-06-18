//
//  VaultSetupViewModel.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import Foundation
import Combine

final class VaultSetupViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var masterPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var recoveryPassphrase: String = RecoveryPassphraseGenerator.generate12DigitPassphrase()
    @Published var hasSavedPassphrase: Bool = false
    @Published var enableBiometrics: Bool = true

    var usernameError: String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "Username is required."
        }

        if trimmed.count < 3 {
            return "Username must be at least 3 characters."
        }

        return nil
    }

    var isUsernameValid: Bool {
        usernameError == nil
    }

    var passwordValidation: PasswordValidationResult {
        PasswordValidator.validate(masterPassword)
    }

    var isPasswordStrong: Bool {
        passwordValidation.isStrong
    }

    var passwordMatchError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return masterPassword == confirmPassword ? nil : "Passwords do not match."
    }

    var canContinueFromPassword: Bool {
        isPasswordStrong &&
        !confirmPassword.isEmpty &&
        masterPassword == confirmPassword
    }

    var canContinueFromPassphrase: Bool {
        hasSavedPassphrase
    }

    func regeneratePassphrase() {
        recoveryPassphrase = RecoveryPassphraseGenerator.generate12DigitPassphrase()
        hasSavedPassphrase = false
    }

    func buildPrototypeSecret() -> String {
//        VaultSecretBuilder.buildPrototypeCombinedSecret(
//            password: masterPassword,
//            passphrase: recoveryPassphrase
//        )
        "Prototype Secret"
    }
}
