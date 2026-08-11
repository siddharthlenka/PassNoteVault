//
//  PasswordEntry.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation
import GRDB

struct PasswordEntry: Identifiable, Hashable {
    let id: String
    let accountName: String
    let username: String?
    let password: String
    let createdAt: Date

    nonisolated init(
        id: String = UUID().uuidString,
        accountName: String,
        username: String? = nil,
        password: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.accountName = accountName
        self.username = username
        self.password = password
        self.createdAt = createdAt
    }
}

extension PasswordEntry {
    init(row: Row) {
        id = row["id"]
        accountName = row["accountName"]
        username = row["username"]
        password = row["password"]

        let timestamp: Double = row["createdAt"]
        createdAt = Date(timeIntervalSince1970: timestamp)
    }
}
