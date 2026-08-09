//
//  ExportSupport.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import Foundation

enum ExportAuthorizationError: Error {
    case incorrectMasterPassword
}

enum ExportSupport {
    static func verifyMasterPassword(_ masterPassword: String) throws {
        var vaultKey = try VaultDatabase.shared.recoverVaultKey(masterPassword: masterPassword)
        vaultKey.resetBytes(in: 0..<vaultKey.count)
    }

    static func dateStamp(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func passwordFilename() -> String {
        "PassNote_Passwords_\(dateStamp()).pnpass"
    }

    static func singleNoteFilename() -> String {
        "PassNote_Note_\(dateStamp()).pnnote"
    }

    static func selectedNotesFilename(count: Int) -> String {
        "PassNote_Notes_\(count)_\(dateStamp()).pnnote"
    }

    static func allNotesFilename() -> String {
        "PassNote_AllNotes_\(dateStamp()).pnnote"
    }

    static func vaultBackupFilename() -> String {
        "PassAndNote_Backup_\(dateStamp()).pnvault"
    }

    static func plainTextNoteFilename(_ note: SecureNote) -> String {
        let trimmed = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = trimmed.isEmpty ? "PassNote_Note" : trimmed
        return "\(sanitizedFilename(baseName))_\(dateStamp()).txt"
    }

    private static func sanitizedFilename(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
            .union(.newlines)
        let components = value.components(separatedBy: invalidCharacters)
        let sanitized = components
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitized.isEmpty ? "PassNote_Note" : sanitized
    }
}
