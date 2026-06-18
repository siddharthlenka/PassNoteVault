//
//  PasswordValidationResult.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import Foundation

struct PasswordValidationResult {
    let hasMinimumLength: Bool
    let hasUppercase: Bool
    let hasLowercase: Bool
    let hasNumber: Bool
    let hasSpecialCharacter: Bool

    var isStrong: Bool {
        hasMinimumLength &&
        hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecialCharacter
    }
}

enum PasswordValidator {
    static func validate(_ password: String) -> PasswordValidationResult {
        PasswordValidationResult(
            hasMinimumLength: password.count >= 12,
            hasUppercase: password.range(of: "[A-Z]", options: .regularExpression) != nil,
            hasLowercase: password.range(of: "[a-z]", options: .regularExpression) != nil,
            hasNumber: password.range(of: "[0-9]", options: .regularExpression) != nil,
            hasSpecialCharacter: password.range(of: #"[^A-Za-z0-9]"#, options: .regularExpression) != nil
        )
    }
}