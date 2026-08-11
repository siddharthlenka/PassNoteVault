//
//  ImportSupport.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import Foundation
import GRDB

enum ImportSupportError: Error, LocalizedError {
    case unsupportedFileType
    case emptyPlainTextNote
    case emptyImport
    case databaseUnavailable

    var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "This file type cannot be imported here."
        case .emptyPlainTextNote:
            return "This text file is empty."
        case .emptyImport:
            return "This backup does not contain any records to import."
        case .databaseUnavailable:
            return "Database is not open."
        }
    }
}

struct VaultImportSummary: Identifiable {
    let id = UUID()
    let container: EncryptedExportContainer
    let payload: FullVaultExportPayload

    var passwordCount: Int { payload.passwords.count }
    var noteCount: Int { payload.notes.count }
    var totalCount: Int { passwordCount + noteCount }
}

enum ImportSupport {
    static func readFileData(from url: URL) throws -> Data {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try Data(contentsOf: url)
    }

    static func validateExtension(
        for url: URL,
        allowedExtensions: Set<String>
    ) throws {
        let fileExtension = url.pathExtension.lowercased()
        guard allowedExtensions.contains(fileExtension) else {
            throw ImportSupportError.unsupportedFileType
        }
    }

    nonisolated static func passwordEntry(from dto: PasswordExportDTO) throws -> PasswordEntry {
        let accountName = dto.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = dto.username?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accountName.isEmpty, !dto.password.isEmpty else {
            throw ImportDecryptionError.invalidPayload
        }

        return PasswordEntry(
            accountName: accountName,
            username: username?.isEmpty == true ? nil : username,
            password: dto.password,
            createdAt: dto.createdAt
        )
    }

    nonisolated static func secureNote(from dto: NoteExportDTO) throws -> SecureNote {
        let trimmedTitle = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedTitle.isEmpty ? SecureNoteTitleBuilder.makeTitle(from: dto.content) : trimmedTitle

        return SecureNote(
            title: title,
            content: dto.content,
            isTitleManuallyRenamed: dto.isTitleManuallyRenamed,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    static func importFullVaultPayload(_ payload: FullVaultExportPayload) throws {
        guard payload.payloadVersion == 1 else {
            throw ImportDecryptionError.unsupportedVersion
        }

        let passwords = try payload.passwords.map(passwordEntry(from:))
        let notes = try payload.notes.map(secureNote(from:))

        guard !passwords.isEmpty || !notes.isEmpty else {
            throw ImportSupportError.emptyImport
        }

        guard let dbQueue = VaultDatabase.shared.dbQueue else {
            throw ImportSupportError.databaseUnavailable
        }

        try dbQueue.write { db in
            for password in passwords {
                try PasswordVaultRepository.insert(password, in: db)
            }

            for note in notes {
                try SecureNotesRepository.insert(note, in: db)
            }
        }

        VaultSettingsMetadata.markPasswordsAdded(count: passwords.count)
        VaultSettingsMetadata.markNotesAdded(count: notes.count)
    }

    static func plaintextImportedNote(from data: Data) throws -> SecureNote {
        guard let content = String(data: data, encoding: .utf8),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportSupportError.emptyPlainTextNote
        }

        return SecureNote(
            title: SecureNoteTitleBuilder.makeTitle(from: content),
            content: content
        )
    }

    static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return "Import failed. Please try again."
    }
}
