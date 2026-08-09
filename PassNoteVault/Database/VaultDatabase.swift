//
//  VaultDatabase.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation
import GRDB

final class VaultDatabase {
    static let shared = VaultDatabase()

    private init() {}

    private(set) var dbQueue: DatabaseQueue?

    func open(passphrase: String) throws {
        if dbQueue != nil {
            return
        }

        let dbURL = try databaseURL()

        print("Vault DB path:", dbURL.path)

        var config = Configuration()
        config.prepareDatabase { db in
            try db.usePassphrase(passphrase)
        }

        let queue = try DatabaseQueue(path: dbURL.path, configuration: config)

        try migrate(queue)

        dbQueue = queue

        try queue.read { db in
            let cipherVersion = try String.fetchOne(db, sql: "PRAGMA cipher_version;")
            print("SQLCipher version:", cipherVersion ?? "nil")

            let tables = try String.fetchAll(db, sql: """
                SELECT name
                FROM sqlite_master
                WHERE type = 'table'
            """)

            print("Vault DB tables:", tables)
        }
    }

    func close() {
        dbQueue = nil
    }

    private func databaseURL() throws -> URL {
        let folderURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let appFolderURL = folderURL.appendingPathComponent("PrivateVault", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appFolderURL.path) {
            try FileManager.default.createDirectory(
                at: appFolderURL,
                withIntermediateDirectories: true
            )
        }

        return appFolderURL.appendingPathComponent("vault.sqlite")
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
