//
//  SecureKeychainStore.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 08/08/26.
//

import Foundation
import Security

enum SecureKeychainError: Error {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case invalidData
}

final class SecureKeychainStore {

    static let shared = SecureKeychainStore()

    private let service = "com.passnotevault.security"

    private init() {}

    func save(
        _ data: Data,
        account: String
    ) throws {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            updateAttributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw SecureKeychainError.saveFailed(updateStatus)
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,

            kSecAttrAccessible as String:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,

            kSecValueData as String: data
        ]

        let addStatus = SecItemAdd(
            addQuery as CFDictionary,
            nil
        )

        guard addStatus == errSecSuccess else {
            throw SecureKeychainError.saveFailed(addStatus)
        }
    }

    func read(account: String) throws -> Data {
        guard let data = try readIfExists(account: account) else {
            throw SecureKeychainError.readFailed(errSecItemNotFound)
        }

        return data
    }

    func readIfExists(account: String) throws -> Data? {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,

            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw SecureKeychainError.readFailed(status)
        }

        guard let data = result as? Data else {
            throw SecureKeychainError.invalidData
        }

        return data
    }

    func delete(account: String) {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
