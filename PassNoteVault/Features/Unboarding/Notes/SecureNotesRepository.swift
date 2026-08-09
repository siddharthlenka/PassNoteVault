//
//  SecureNotesRepository.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import Foundation
import GRDB

final class SecureNotesRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func fetchNotes() throws -> [SecureNote] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, title, content, isTitleManuallyRenamed, createdAt, updatedAt
                FROM secure_notes
                ORDER BY updatedAt DESC
            """)

            return rows.map { SecureNote(row: $0) }
        }
    }

    func createEmptyNote() throws -> SecureNote {
        let note = SecureNote(
            title: "Untitled Note",
            content: ""
        )

        try dbQueue.write { db in
            try Self.insert(note, in: db)
        }

        return note
    }

    func importNotes(_ notes: [SecureNote]) throws {
        try dbQueue.write { db in
            for note in notes {
                try Self.insert(note, in: db)
            }
        }
    }

    func updateNoteContent(noteID: String, content: String) throws {
        let autoTitle = SecureNoteTitleBuilder.makeTitle(from: content)
        let updatedAt = Date().timeIntervalSince1970

        try dbQueue.write { db in
            try db.execute(
                sql: """
                    UPDATE secure_notes
                    SET
                        content = ?,
                        title = CASE
                            WHEN isTitleManuallyRenamed = 0 THEN ?
                            ELSE title
                        END,
                        updatedAt = ?
                    WHERE id = ?
                """,
                arguments: [
                    content,
                    autoTitle,
                    updatedAt,
                    noteID
                ]
            )
        }
    }

    func renameNote(noteID: String, title: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            return
        }

        try dbQueue.write { db in
            try db.execute(
                sql: """
                    UPDATE secure_notes
                    SET
                        title = ?,
                        isTitleManuallyRenamed = 1,
                        updatedAt = ?
                    WHERE id = ?
                """,
                arguments: [
                    trimmedTitle,
                    Date().timeIntervalSince1970,
                    noteID
                ]
            )
        }
    }

    func deleteNote(noteID: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    DELETE FROM secure_notes
                    WHERE id = ?
                """,
                arguments: [noteID]
            )
        }
    }

    func deleteNoteIfContentIsEmpty(noteID: String, content: String) throws {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedContent.isEmpty else {
            return
        }

        try deleteNote(noteID: noteID)
    }

    static func insert(_ note: SecureNote, in db: Database) throws {
        try db.execute(
            sql: """
                INSERT INTO secure_notes (
                    id,
                    title,
                    content,
                    isTitleManuallyRenamed,
                    createdAt,
                    updatedAt
                )
                VALUES (?, ?, ?, ?, ?, ?)
            """,
            arguments: [
                note.id,
                note.title,
                note.content,
                note.isTitleManuallyRenamed ? 1 : 0,
                note.createdAt.timeIntervalSince1970,
                note.updatedAt.timeIntervalSince1970
            ]
        )
    }
}
