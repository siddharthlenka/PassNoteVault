//
//  VaultKeychainError.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 18/06/26.
//


import Foundation
import Security

enum VaultKeychainError: Error {
    case dataConversionFailed
    case unhandledStatus(OSStatus)
}

final class VaultKeychainService {
    static let shared = VaultKeychainService()

    private init() {}

    private var serviceName: String {
        Bundle.main.bundleIdentifier ?? "PrivateVaultApp"
    }

    func saveString(_ value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw VaultKeychainError.dataConversionFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(item as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw VaultKeychainError.unhandledStatus(status)
        }
    }

    func readString(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw VaultKeychainError.unhandledStatus(status)
        }

        guard let data = result as? Data else {
            throw VaultKeychainError.dataConversionFailed
        }

        return String(data: data, encoding: .utf8)
    }

    func deleteString(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw VaultKeychainError.unhandledStatus(status)
        }
    }
}