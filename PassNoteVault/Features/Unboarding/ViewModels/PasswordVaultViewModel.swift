//
//  PasswordVaultViewModel.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation
import Combine

final class PasswordVaultViewModel: ObservableObject {
    @Published private(set) var entries: [PasswordEntry] = []
    @Published var errorMessage: String?

    func loadPasswords() {
        /*
         TODO later:
         Fetch saved password records from encrypted SQLCipher database.
         */

        entries = entries
    }

    func savePassword(accountName: String, password: String) {
        let trimmedAccountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedAccountName.isEmpty else {
            errorMessage = "Account name is required."
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required."
            return
        }

        /*
         TODO later:
         Save this record inside SQLCipher encrypted database.
         For now, this is memory-only prototype storage.
         */

        let entry = PasswordEntry(
            accountName: trimmedAccountName,
            password: password
        )

        entries.insert(entry, at: 0)
        errorMessage = nil
    }
}