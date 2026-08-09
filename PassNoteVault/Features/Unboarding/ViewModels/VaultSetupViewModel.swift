//
//  VaultSetupViewModel.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import Foundation
import Combine

final class VaultSetupViewModel: ObservableObject {
    @Published var masterPassword: String = ""
    @Published var confirmPassword: String = ""

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

    func clearSensitiveInputs() {
        masterPassword = ""
        confirmPassword = ""
    }
}
