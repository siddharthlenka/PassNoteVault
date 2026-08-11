//
//  ImportDecryptionService.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import CryptoKit
import Foundation

enum ImportDecryptionError: Error, LocalizedError {
    case fileTooLarge
    case invalidContainer
    case unsupportedVersion
    case unsupportedContentType
    case unsupportedEncryption
    case unsupportedKDF
    case decryptionFailed
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "This backup file is too large to import."
        case .invalidContainer:
            return "This is not a valid Pass&Note Vault backup file."
        case .unsupportedVersion:
            return "This backup was created with an unsupported export format."
        case .unsupportedContentType:
            return "This backup type cannot be imported here."
        case .unsupportedEncryption, .unsupportedKDF:
            return "This backup uses unsupported encryption settings."
        case .decryptionFailed:
            return "Unable to decrypt this backup. Check the Backup Password or verify that the file is not corrupted."
        case .invalidPayload:
            return "This backup contains invalid data."
        }
    }
}

struct DecryptedImportPackage<Payload> {
    let container: EncryptedExportContainer
    let payload: Payload
}

enum ImportDecryptionService {
    static let maximumEncryptedImportSize = 25 * 1024 * 1024

    static func decrypt<Payload: Decodable>(
        data: Data,
        backupPassword: String,
        expectedContentType: ExportContentType,
        payloadType: Payload.Type
    ) throws -> DecryptedImportPackage<Payload> {
        guard data.count <= maximumEncryptedImportSize else {
            throw ImportDecryptionError.fileTooLarge
        }

        let decoder = JSONDecoder.passNoteExportDecoder
        let container: EncryptedExportContainer

        do {
            container = try decoder.decode(EncryptedExportContainer.self, from: data)
        } catch {
            throw ImportDecryptionError.invalidContainer
        }

        try validate(container: container, expectedContentType: expectedContentType)

        var exportKey = try PasswordKeyDeriver.deriveKey(
            password: backupPassword,
            salt: container.salt,
            iterations: container.kdf.iterations
        )

        defer {
            exportKey.resetBytes(in: 0..<exportKey.count)
        }

        let payloadData: Data
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: container.sealedPayload)
            payloadData = try AES.GCM.open(sealedBox, using: SymmetricKey(data: exportKey))
        } catch {
            throw ImportDecryptionError.decryptionFailed
        }

        do {
            let payload = try decoder.decode(Payload.self, from: payloadData)
            return DecryptedImportPackage(container: container, payload: payload)
        } catch {
            throw ImportDecryptionError.invalidPayload
        }
    }

    static func validate(
        container: EncryptedExportContainer,
        expectedContentType: ExportContentType
    ) throws {
        guard container.magic == EncryptedExportContainer.magicIdentifier else {
            throw ImportDecryptionError.invalidContainer
        }

        guard container.formatVersion == EncryptedExportContainer.currentFormatVersion else {
            throw ImportDecryptionError.unsupportedVersion
        }

        guard container.contentType == expectedContentType else {
            throw ImportDecryptionError.unsupportedContentType
        }

        guard container.encryption.algorithm == "AES-256-GCM",
              container.encryption.version == 1 else {
            throw ImportDecryptionError.unsupportedEncryption
        }

        guard container.kdf.algorithm == "PBKDF2-HMAC-SHA256",
              container.kdf.version == 1,
              container.kdf.keyLength == PasswordKeyDeriver.keyLength else {
            throw ImportDecryptionError.unsupportedKDF
        }

        guard container.itemCount >= 0 else {
            throw ImportDecryptionError.invalidContainer
        }
    }
}

extension JSONDecoder {
    static var passNoteExportDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
