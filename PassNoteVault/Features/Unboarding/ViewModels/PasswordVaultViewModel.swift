//
//  PasswordVaultViewModel.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation
import Combine

@MainActor
final class PasswordVaultViewModel: ObservableObject {
    @Published private(set) var entries: [PasswordEntry] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var repository: PasswordVaultRepository? {
        guard let dbQueue = VaultDatabase.shared.dbQueue else {
            return nil
        }

        return PasswordVaultRepository(dbQueue: dbQueue)
    }

    func loadPasswords() {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            entries = try repository.fetchPasswords()
            errorMessage = nil
            successMessage = nil
        } catch {
            print("Fetch passwords failed:", error)
            errorMessage = "Could not load saved passwords."
        }
    }

    func savePassword(accountName: String, username: String?, password: String) {
        let trimmedAccountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedAccountName.isEmpty else {
            errorMessage = "Account name is required."
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required."
            return
        }

        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.insertPassword(
                accountName: trimmedAccountName,
                username: trimmedUsername?.isEmpty == true ? nil : trimmedUsername,
                password: password
            )
            VaultSettingsMetadata.markPasswordsAdded()

            entries = try repository.fetchPasswords()
            errorMessage = nil
            successMessage = nil
        } catch {
            print("Save password failed:", error)
            errorMessage = "Could not save password."
        }
    }

    func deletePassword(_ entry: PasswordEntry) {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.deletePassword(id: entry.id)
            entries = try repository.fetchPasswords()
            errorMessage = nil
            successMessage = nil
        } catch {
            print("Delete password failed:", error)
            errorMessage = "Could not delete password."
        }
    }

    func deletePasswords(_ selectedEntries: [PasswordEntry]) {
        guard !selectedEntries.isEmpty else {
            return
        }

        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            for entry in selectedEntries {
                try repository.deletePassword(id: entry.id)
            }

            entries = try repository.fetchPasswords()
            errorMessage = nil
            successMessage = nil
        } catch {
            print("Delete passwords failed:", error)
            errorMessage = "Could not delete selected passwords."
        }
    }

    func importPasswords(_ importedEntries: [PasswordEntry]) {
        guard !importedEntries.isEmpty else {
            errorMessage = "No passwords to import."
            return
        }

        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.importPasswords(importedEntries)
            VaultSettingsMetadata.markPasswordsAdded(count: importedEntries.count)
            entries = try repository.fetchPasswords()
            errorMessage = nil
            successMessage = "\(importedEntries.count) passwords imported."
        } catch {
            print("Import passwords failed:", error)
            errorMessage = "Could not import passwords."
        }
    }
}
