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
    @Published var successMessage: String?

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
            successMessage = nil
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
            successMessage = nil
            return note
        } catch {
            print("Create note failed:", error)
            errorMessage = "Could not create note."
            return nil
        }
    }

    func createImportedPlainTextNoteForEditing(_ importedNote: SecureNote) -> SecureNote? {
        guard let repository else {
            errorMessage = "Database is not open."
            return nil
        }

        do {
            let note = try repository.createEmptyNote()
            notes = try repository.fetchNotes()
            errorMessage = nil
            successMessage = nil
            return SecureNote(
                id: note.id,
                title: importedNote.title,
                content: importedNote.content,
                isTitleManuallyRenamed: false,
                createdAt: note.createdAt,
                updatedAt: note.updatedAt
            )
        } catch {
            print("Create imported note failed:", error)
            errorMessage = "Could not create imported note."
            return nil
        }
    }

    func saveNoteContent(noteID: String, content: String) {
        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            let didCreateContent = try repository.updateNoteContent(noteID: noteID, content: content)
            if didCreateContent {
                VaultSettingsMetadata.markNotesAdded()
            }
            notes = try repository.fetchNotes()
            errorMessage = nil
            successMessage = nil
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
            successMessage = nil
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
            successMessage = nil
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
            successMessage = nil
        } catch {
            print("Rename note failed:", error)
            errorMessage = "Could not rename note."
        }
    }

    func importNotes(_ importedNotes: [SecureNote]) {
        guard !importedNotes.isEmpty else {
            errorMessage = "No notes to import."
            return
        }

        guard let repository else {
            errorMessage = "Database is not open."
            return
        }

        do {
            try repository.importNotes(importedNotes)
            VaultSettingsMetadata.markNotesAdded(count: importedNotes.count)
            notes = try repository.fetchNotes()
            errorMessage = nil
            successMessage = "\(importedNotes.count) notes imported."
        } catch {
            print("Import notes failed:", error)
            errorMessage = "Could not import notes."
        }
    }
}
