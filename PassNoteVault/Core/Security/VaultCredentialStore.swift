//
//  VaultCredentialStore.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 18/06/26.
//


import Foundation

enum VaultCredentialStore {
    private enum Key {
        static let username = "vault.username"
        static let password = "vault.masterPassword"
    }

    static var savedUsername: String? {
        try? VaultKeychainService.shared.readString(account: Key.username)
    }

    static func save(username: String, password: String) throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        try VaultKeychainService.shared.saveString(trimmedUsername, account: Key.username)
        try VaultKeychainService.shared.saveString(password, account: Key.password)
    }

    static func validate(username: String, password: String) -> Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let savedUsername = try? VaultKeychainService.shared.readString(account: Key.username),
            let savedPassword = try? VaultKeychainService.shared.readString(account: Key.password)
        else {
            return false
        }

        return trimmedUsername == savedUsername && password == savedPassword
    }

    static func clear() throws {
        try VaultKeychainService.shared.deleteString(account: Key.username)
        try VaultKeychainService.shared.deleteString(account: Key.password)
    }
}