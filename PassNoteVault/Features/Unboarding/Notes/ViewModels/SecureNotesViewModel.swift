//
//  SecureNotesViewModel.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import Foundation
import Combine

@MainActor
final class SecureNotesViewModel: ObservableObject {
    @Published private(set) var notes: [SecureNote] = []
    @Published var errorMessage: String?

    private var repository: SecureNotesRepository? {
        guard let dbQueue = VaultDatabase.shared.dbQueue else {
            return nil
        }

        return SecureNotesRepository(dbQueue: dbQueue)
    }

    func loadNotes() {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            notes = try repository.fetchNotes()
            errorMessage = nil
        } catch {
            print("Fetch notes failed:", error)
            errorMessage = "Could not load notes."
        }
    }

    func createNoteForEditing() -> SecureNote? {
        guard let repository else {
            errorMessage = "Database is not open."
            return nil
        }

        do {
            let note = try repository.createEmptyNote()
            notes = try repository.fetchNotes()
            errorMessage = nil
            return note
        } catch {
            print("Create note failed:", error)
            errorMessage = "Could not create note."
            return nil
        }
    }

    func saveNoteContent(noteID: String, content: String) {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.updateNoteContent(noteID: noteID, content: content)
            notes = try repository.fetchNotes()
            errorMessage = nil
        } catch {
            print("Save note failed:", error)
            errorMessage = "Could not save note."
        }
    }

    func deleteNoteIfEmpty(noteID: String, content: String) {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.deleteNoteIfContentIsEmpty(
                noteID: noteID,
                content: content
            )

            notes = try repository.fetchNotes()
            errorMessage = nil
        } catch {
            print("Delete empty note failed:", error)
        }
    }

    func deleteNote(_ note: SecureNote) {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.deleteNote(noteID: note.id)
            notes = try repository.fetchNotes()
            errorMessage = nil
        } catch {
            print("Delete note failed:", error)
            errorMessage = "Could not delete note."
        }
    }

    func renameNote(_ note: SecureNote, title: String) {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.renameNote(noteID: note.id, title: title)
            notes = try repository.fetchNotes()
            errorMessage = nil
        } catch {
            print("Rename note failed:", error)
            errorMessage = "Could not rename note."
        }
    }
}