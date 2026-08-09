//
//  SecureNote.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import Foundation
import GRDB

struct SecureNote: Identifiable, Hashable {
    let id: String
    let title: String
    let content: String
    let isTitleManuallyRenamed: Bool
    let createdAt: Date
    let updatedAt: Date

    nonisolated init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        isTitleManuallyRenamed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.isTitleManuallyRenamed = isTitleManuallyRenamed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension SecureNote {
    init(row: Row) {
        id = row["id"]
        title = row["title"]
        content = row["content"]

        let manualTitleValue: Int = row["isTitleManuallyRenamed"]
        isTitleManuallyRenamed = manualTitleValue == 1

        let createdTimestamp: Double = row["createdAt"]
        let updatedTimestamp: Double = row["updatedAt"]

        createdAt = Date(timeIntervalSince1970: createdTimestamp)
        updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
    }
}
