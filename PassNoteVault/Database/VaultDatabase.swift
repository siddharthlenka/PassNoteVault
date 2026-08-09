//
//  VaultDatabase.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation
import GRDB

enum VaultDatabaseError: Error {
    case missingVaultKeyEnvelope
    case cannotResetActivatedVault
}

final class VaultDatabase {
    static let shared = VaultDatabase()

    private init() {}

    private(set) var dbQueue: DatabaseQueue?

    func create(masterPassword: String) throws {
        var vaultKey = try SecureRandom.data(count: VaultKeyEnvelope.vaultKeyByteCount)

        defer {
            vaultKey.resetBytes(in: 0..<vaultKey.count)
        }

        let envelope = try VaultKeyEnvelope.create(
            masterPassword: masterPassword,
            vaultKey: vaultKey
        )

        do {
            try VaultKeyEnvelopeStore.shared.save(envelope)
            try openDatabase(using: vaultKey)
            VaultLifecycleMetadata.prepareNewVaultLifecycle()
        } catch {
            VaultKeyEnvelopeStore.shared.delete()
            dbQueue = nil
            throw error
        }
    }

    func open(masterPassword: String) throws {
        guard let storedEnvelope = try VaultKeyEnvelopeStore.shared.readStoredEnvelope() else {
            throw VaultDatabaseError.missingVaultKeyEnvelope
        }

        switch storedEnvelope {
        case .current(let envelope):
            var vaultKey = try envelope.unwrapVaultKey(masterPassword: masterPassword)

            defer {
                vaultKey.resetBytes(in: 0..<vaultKey.count)
            }

            try openDatabase(using: vaultKey)

        case .legacy(let legacyEnvelope):
            try migrateLegacyEnvelope(
                legacyEnvelope,
                masterPassword: masterPassword
            )
        }
    }

    func open(vaultKey: Data) throws {
        try openDatabase(using: vaultKey)
    }

    func recoverVaultKey(masterPassword: String) throws -> Data {
        guard let storedEnvelope = try VaultKeyEnvelopeStore.shared.readStoredEnvelope() else {
            throw VaultDatabaseError.missingVaultKeyEnvelope
        }

        switch storedEnvelope {
        case .current(let envelope):
            return try envelope.unwrapVaultKey(masterPassword: masterPassword)

        case .legacy(let legacyEnvelope):
            return try PasswordKeyDeriver.deriveKey(
                password: masterPassword,
                salt: legacyEnvelope.salt,
                iterations: legacyEnvelope.iterations
            )
        }
    }

    func close() {
        dbQueue = nil
    }

    func resetUnusedVault() throws {
        guard VaultLifecycleMetadata.canResetUnusedVault else {
            throw VaultDatabaseError.cannotResetActivatedVault
        }

        close()
        try removeDatabaseFiles()
        VaultKeyEnvelopeStore.shared.delete()
        BiometricVaultKeyService.shared.disable()
        VaultLifecycleMetadata.clearUnusedVaultLifecycle()
    }

    private func migrateLegacyEnvelope(
        _ legacyEnvelope: LegacyVaultKeyEnvelope,
        masterPassword: String
    ) throws {
        var vaultKey = try PasswordKeyDeriver.deriveKey(
            password: masterPassword,
            salt: legacyEnvelope.salt,
            iterations: legacyEnvelope.iterations
        )

        defer {
            vaultKey.resetBytes(in: 0..<vaultKey.count)
        }

        try openDatabase(using: vaultKey)

        let migratedEnvelope = try VaultKeyEnvelope.create(
            masterPassword: masterPassword,
            vaultKey: vaultKey
        )
        try VaultKeyEnvelopeStore.shared.save(migratedEnvelope)
    }

    private func openDatabase(using vaultKey: Data) throws {
        if dbQueue != nil {
            return
        }

        let dbURL = try databaseURL()

        var config = Configuration()
        config.prepareDatabase { db in
            try db.usePassphrase(vaultKey)
        }

        let queue = try DatabaseQueue(path: dbURL.path, configuration: config)

        try migrate(queue)

        dbQueue = queue
    }

    private func databaseURL() throws -> URL {
        let appFolderURL = try appSupportFolderURL(createIfNeeded: true)
        return appFolderURL.appendingPathComponent("vault.sqlite")
    }

    private func appSupportFolderURL(createIfNeeded: Bool) throws -> URL {
        let folderURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: createIfNeeded
        )

        let appFolderURL = folderURL.appendingPathComponent("PrivateVault", isDirectory: true)

        if createIfNeeded && !FileManager.default.fileExists(atPath: appFolderURL.path) {
            try FileManager.default.createDirectory(
                at: appFolderURL,
                withIntermediateDirectories: true
            )
        }

        return appFolderURL
    }

    private func removeDatabaseFiles() throws {
        let appFolderURL = try appSupportFolderURL(createIfNeeded: false)
        let dbURL = appFolderURL.appendingPathComponent("vault.sqlite")
        let relatedURLs = [
            dbURL,
            URL(fileURLWithPath: dbURL.path + "-wal"),
            URL(fileURLWithPath: dbURL.path + "-shm"),
            URL(fileURLWithPath: dbURL.path + "-journal")
        ]

        for url in relatedURLs where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func migrate(_ dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS password_entries (
                    id TEXT PRIMARY KEY NOT NULL,
                    accountName TEXT NOT NULL,
                    password TEXT NOT NULL,
                    createdAt DOUBLE NOT NULL
                )
            """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS secure_notes (
                    id TEXT PRIMARY KEY NOT NULL,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL,
                    isTitleManuallyRenamed INTEGER NOT NULL DEFAULT 0,
                    createdAt DOUBLE NOT NULL,
                    updatedAt DOUBLE NOT NULL
                )
            """)
        }
    }
}
