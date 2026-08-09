//
//  ExportPayloads.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import Foundation

enum ExportContentType: String, Codable {
    case passwords
    case notes
    case fullVault
}

struct PasswordExportDTO: Codable {
    let accountName: String
    let password: String
    let createdAt: Date

    nonisolated init(entry: PasswordEntry) {
        accountName = entry.accountName
        password = entry.password
        createdAt = entry.createdAt
    }
}

struct NoteExportDTO: Codable {
    let title: String
    let content: String
    let isTitleManuallyRenamed: Bool
    let createdAt: Date
    let updatedAt: Date

    nonisolated init(note: SecureNote) {
        title = note.title
        content = note.content
        isTitleManuallyRenamed = note.isTitleManuallyRenamed
        createdAt = note.createdAt
        updatedAt = note.updatedAt
    }
}

struct PasswordExportPayload: Codable {
    let payloadVersion: Int
    let passwords: [PasswordExportDTO]

    init(passwords: [PasswordExportDTO]) {
        payloadVersion = 1
        self.passwords = passwords
    }
}

struct NoteExportPayload: Codable {
    let payloadVersion: Int
    let notes: [NoteExportDTO]

    init(notes: [NoteExportDTO]) {
        payloadVersion = 1
        self.notes = notes
    }
}

struct FullVaultExportPayload: Codable {
    let payloadVersion: Int
    let passwords: [PasswordExportDTO]
    let notes: [NoteExportDTO]

    init(passwords: [PasswordExportDTO], notes: [NoteExportDTO]) {
        payloadVersion = 1
        self.passwords = passwords
        self.notes = notes
    }
}
