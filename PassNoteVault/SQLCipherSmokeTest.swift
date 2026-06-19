//
//  SQLCipherSmokeTest.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 18/06/26.
//


import Foundation
import GRDB

final class SQLCipherSmokeTest {
    
    static let shared = SQLCipherSmokeTest()
    
    private let dbQueue: DatabaseQueue
    
    private init() {
        do {
            let dbURL = try Self.makeDatabaseURL()
            
            var config = Configuration()
            
            config.prepareDatabase { db in
                // Test passphrase only.
                // Later this should come from your vault password/passphrase flow.
                try db.usePassphrase("test-vault-passphrase-123")
                
                // Optional normal SQLite setting.
                try db.execute(sql: "PRAGMA foreign_keys = ON")
                
                // Main check: if this returns value, SQLCipher is loaded.
                let cipherVersion = try String.fetchOne(db, sql: "PRAGMA cipher_version")
                
                guard let cipherVersion else {
                    throw NSError(
                        domain: "SQLCipherSmokeTest",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "SQLCipher is NOT loaded"]
                    )
                }
                
                print("✅ SQLCipher loaded:", cipherVersion)
            }
            
            dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
            
        } catch {
            fatalError("❌ Database open failed: \(error)")
        }
    }
    
    func runTest() {
        do {
            try dbQueue.write { db in
                try db.create(table: "test_items", ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("title", .text).notNull()
                    t.column("createdAt", .text).notNull()
                }
                
                try db.execute(
                    sql: """
                    INSERT INTO test_items (title, createdAt)
                    VALUES (?, ?)
                    """,
                    arguments: ["First encrypted item", Date().description]
                )
            }
            
            let count = try dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM test_items") ?? 0
            }
            
            print("✅ Encrypted DB write/read success. Row count:", count)
            
        } catch {
            print("❌ SQLCipher DB test failed:", error)
        }
    }
    
    private static func makeDatabaseURL() throws -> URL {
        let appSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let folderURL = appSupportURL.appendingPathComponent("PassNoteVault", isDirectory: true)
        
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
        
        return folderURL.appendingPathComponent("vault-test.sqlite")
    }
}