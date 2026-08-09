//
//  ExportFileTypes.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let passNoteEncryptedExport = UTType.data
}

struct EncryptedExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.passNoteEncryptedExport, .plainText]
    }

    let data: Data
    let contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        contentType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct PlainTextNoteDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.plainText]
    }

    let text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        text = String(data: data, encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct PreparedEncryptedExport: Identifiable {
    let id = UUID()
    let document: EncryptedExportDocument
    let filename: String
}

struct PreparedPlainTextExport: Identifiable {
    let id = UUID()
    let document: PlainTextNoteDocument
    let filename: String
}
