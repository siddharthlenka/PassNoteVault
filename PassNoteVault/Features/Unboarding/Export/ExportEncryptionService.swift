//
//  ExportEncryptionService.swift
//  PassNoteVault
//

import CryptoKit
import Foundation

enum ExportEncryptionError: Error {
    case invalidSealedPayload
}

struct EncryptedExportContainer: Codable {
    static let magicIdentifier = "PASSNOTE"
    static let currentFormatVersion = 1

    let magic: String
    let formatVersion: Int
    let contentType: ExportContentType
    let itemCount: Int
    let createdAt: Date
    let encryption: ExportEncryptionMetadata
    let kdf: ExportKDFMetadata
    let salt: Data
    let sealedPayload: Data
}

struct ExportEncryptionMetadata: Codable {
    let algorithm: String
    let version: Int
}

struct ExportKDFMetadata: Codable {
    let algorithm: String
    let version: Int
    let iterations: UInt32
    let keyLength: Int
}

enum ExportEncryptionService {
    static let saltByteCount = 32

    static func makeEncryptedExport<Payload: Encodable>(
        payload: Payload,
        contentType: ExportContentType,
        itemCount: Int,
        masterPassword: String
    ) throws -> Data {
        let salt = try SecureRandom.data(count: saltByteCount)
        let iterations = PasswordKeyDeriver.defaultIterations

        var exportKey = try PasswordKeyDeriver.deriveKey(
            password: masterPassword,
            salt: salt,
            iterations: iterations
        )

        defer {
            exportKey.resetBytes(in: 0..<exportKey.count)
        }

        let encoder = JSONEncoder.passNoteExportEncoder
        let payloadData = try encoder.encode(payload)
        let sealedBox = try AES.GCM.seal(
            payloadData,
            using: SymmetricKey(data: exportKey)
        )

        guard let sealedPayload = sealedBox.combined else {
            throw ExportEncryptionError.invalidSealedPayload
        }

        let container = EncryptedExportContainer(
            magic: EncryptedExportContainer.magicIdentifier,
            formatVersion: EncryptedExportContainer.currentFormatVersion,
            contentType: contentType,
            itemCount: itemCount,
            createdAt: Date(),
            encryption: ExportEncryptionMetadata(
                algorithm: "AES-256-GCM",
                version: 1
            ),
            kdf: ExportKDFMetadata(
                algorithm: "PBKDF2-HMAC-SHA256",
                version: 1,
                iterations: iterations,
                keyLength: PasswordKeyDeriver.keyLength
            ),
            salt: salt,
            sealedPayload: sealedPayload
        )

        return try encoder.encode(container)
    }
}

extension JSONEncoder {
    static var passNoteExportEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
