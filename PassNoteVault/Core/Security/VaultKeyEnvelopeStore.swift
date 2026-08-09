//
//  VaultKeyEnvelopeStore.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 08/08/26.
//

import Foundation

enum StoredVaultKeyEnvelope {
    case current(VaultKeyEnvelope)
    case legacy(LegacyVaultKeyEnvelope)
}

final class VaultKeyEnvelopeStore {
    static let shared = VaultKeyEnvelopeStore()

    private let keychainStore: SecureKeychainStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init(keychainStore: SecureKeychainStore = .shared) {
        self.keychainStore = keychainStore
    }

    func save(_ envelope: VaultKeyEnvelope) throws {
        let data = try encoder.encode(envelope)
        try keychainStore.save(data, account: VaultKeyEnvelope.keychainAccount)
    }

    func readStoredEnvelope() throws -> StoredVaultKeyEnvelope? {
        guard let data = try keychainStore.readIfExists(account: VaultKeyEnvelope.keychainAccount) else {
            return nil
        }

        do {
            return .current(try decoder.decode(VaultKeyEnvelope.self, from: data))
        } catch {
            return .legacy(try decoder.decode(LegacyVaultKeyEnvelope.self, from: data))
        }
    }

    func delete() {
        keychainStore.delete(account: VaultKeyEnvelope.keychainAccount)
    }
}
