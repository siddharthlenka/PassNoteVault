//
//  VaultKeyEnvelope.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 08/08/26.
//

import Foundation
import CryptoKit

enum VaultKeyEnvelopeError: Error {
    case unsupportedVersion(Int)
    case invalidVaultKeyLength
    case invalidWrappedVaultKey
    case incorrectMasterPassword
}

struct VaultKeyEnvelope: Codable {
    static let currentVersion = 1
    static let saltByteCount = 32
    static let vaultKeyByteCount = 32
    static let keychainAccount = "vault.keyEnvelope"

    let version: Int
    let salt: Data
    let iterations: UInt32
    let wrappedVaultKey: Data

    static func create(
        masterPassword: String,
        vaultKey: Data
    ) throws -> VaultKeyEnvelope {
        let salt = try SecureRandom.data(count: saltByteCount)
        let iterations = PasswordKeyDeriver.defaultIterations
        let wrappedVaultKey = try wrap(
            vaultKey: vaultKey,
            masterPassword: masterPassword,
            salt: salt,
            iterations: iterations
        )

        return VaultKeyEnvelope(
            version: currentVersion,
            salt: salt,
            iterations: iterations,
            wrappedVaultKey: wrappedVaultKey
        )
    }

    func unwrapVaultKey(masterPassword: String) throws -> Data {
        guard version == Self.currentVersion else {
            throw VaultKeyEnvelopeError.unsupportedVersion(version)
        }

        var kek = try PasswordKeyDeriver.deriveKey(
            password: masterPassword,
            salt: salt,
            iterations: iterations
        )

        defer {
            kek.resetBytes(in: 0..<kek.count)
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: wrappedVaultKey)
            let vaultKey = try AES.GCM.open(
                sealedBox,
                using: SymmetricKey(data: kek)
            )

            guard vaultKey.count == Self.vaultKeyByteCount else {
                throw VaultKeyEnvelopeError.invalidVaultKeyLength
            }

            return vaultKey
        } catch let error as VaultKeyEnvelopeError {
            throw error
        } catch {
            throw VaultKeyEnvelopeError.incorrectMasterPassword
        }
    }

    private static func wrap(
        vaultKey: Data,
        masterPassword: String,
        salt: Data,
        iterations: UInt32
    ) throws -> Data {
        guard vaultKey.count == vaultKeyByteCount else {
            throw VaultKeyEnvelopeError.invalidVaultKeyLength
        }

        var kek = try PasswordKeyDeriver.deriveKey(
            password: masterPassword,
            salt: salt,
            iterations: iterations
        )

        defer {
            kek.resetBytes(in: 0..<kek.count)
        }

        let sealedBox = try AES.GCM.seal(
            vaultKey,
            using: SymmetricKey(data: kek)
        )

        guard let combined = sealedBox.combined else {
            throw VaultKeyEnvelopeError.invalidWrappedVaultKey
        }

        return combined
    }
}

struct LegacyVaultKeyEnvelope: Codable {
    let version: Int
    let salt: Data
    let iterations: UInt32
}
