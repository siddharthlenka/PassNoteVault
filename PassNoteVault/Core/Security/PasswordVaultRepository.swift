//
//  PasswordVaultRepository.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation
import GRDB

final class PasswordVaultRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func fetchPasswords() throws -> [PasswordEntry] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, accountName, password, createdAt
                FROM password_entries
                ORDER BY createdAt DESC
            """)

            return rows.map { PasswordEntry(row: $0) }
        }
    }

    func insertPassword(accountName: String, password: String) throws {
        let entry = PasswordEntry(
            accountName: accountName,
            password: password
        )

        try dbQueue.write { db in
            try Self.insert(entry, in: db)
        }
    }

    func importPasswords(_ entries: [PasswordEntry]) throws {
        try dbQueue.write { db in
            for entry in entries {
                try Self.insert(entry, in: db)
            }
        }
    }

    func deletePassword(id: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    DELETE FROM password_entries
                    WHERE id = ?
                """,
                arguments: [id]
            )
        }
    }

    static func insert(_ entry: PasswordEntry, in db: Database) throws {
        try db.execute(
            sql: """
                INSERT INTO password_entries (
                    id,
                    accountName,
                    password,
                    createdAt
                )
                VALUES (?, ?, ?, ?)
            """,
            arguments: [
                entry.id,
                entry.accountName,
                entry.password,
                entry.createdAt.timeIntervalSince1970
            ]
        )
    }
}
