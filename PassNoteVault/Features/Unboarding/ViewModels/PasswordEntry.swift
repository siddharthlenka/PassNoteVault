//
//  PasswordEntry.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation

struct PasswordEntry: Identifiable, Hashable {
    let id: UUID
    let accountName: String
    let password: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        accountName: String,
        password: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.accountName = accountName
        self.password = password
        self.createdAt = createdAt
    }
}