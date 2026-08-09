//
//  SecureNotesView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import SwiftUI

struct SecureNotesView: View {
    @StateObject private var viewModel = SecureNotesViewModel()

    @State private var selectedNoteForEditor: SecureNote?
    @State private var notePendingDelete: SecureNote?
    @State private var notePendingRename: SecureNote?
    @State private var notePendingExport: SecureNote?

    @State private var renameText = ""
    @State private var isShowingExportDialog = false

    private var isShowingEditor: Binding<Bool> {
        Binding(
            get: {
                selectedNoteForEditor != nil
            },
            set: { newValue in
                if !newValue {
                    selectedNoteForEditor = nil
                    viewModel.loadNotes()
                }
            }
        )
    }

    private var isShowingDeleteAlert: Binding<Bool> {
        Binding(
            get: {
                notePendingDelete != nil
            },
            set: { newValue in
                if !newValue {
                    notePendingDelete = nil
                }
            }
        )
    }

    private var isShowingRenameAlert: Binding<Bool> {
        Binding(
            get: {
                notePendingRename != nil
            },
            set: { newValue in
                if !newValue {
                    notePendingRename = nil
                    renameText = ""
                }
            }
        )
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                headerSection

                if let errorMessage = viewModel.errorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Error",
                        message: errorMessage
                    )
                }

                if viewModel.notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createAndOpenNote()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .navigationDestination(isPresented: isShowingEditor) {
            if let selectedNoteForEditor {
                NoteEditorView(
                    note: selectedNoteForEditor,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete note?", isPresented: isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                notePendingDelete = nil
            }

            Button("Delete", role: .destructive) {
                if let note = notePendingDelete {
                    viewModel.deleteNote(note)
                    notePendingDelete = nil
                }
            }
        } message: {
            if let note = notePendingDelete {
                Text("This will delete \"\(note.title)\".")
            } else {
                Text("This note will be deleted.")
            }
        }
        .alert("Rename note", isPresented: isShowingRenameAlert) {
            TextField("Note title", text: $renameText)

            Button("Cancel", role: .cancel) {
                notePendingRename = nil
                renameText = ""
            }

            Button("Save") {
                if let note = notePendingRename {
                    viewModel.renameNote(note, title: renameText)
                    notePendingRename = nil
                    renameText = ""
                }
            }
        } message: {
            Text("Enter a custom title for this note.")
        }
        .confirmationDialog(
            "Export Note",
            isPresented: $isShowingExportDialog,
            titleVisibility: .visible
        ) {
            Button("Export Unencrypted (.txt)") {
                // TODO later
            }

            Button("Export Encrypted (.passnote)") {
                // TODO later
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Export action will be connected later.")
        }
        .onAppear {
            viewModel.loadNotes()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Secure Notes")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Create private notes stored inside your encrypted vault.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private var emptyState: some View {
        InfoWarningCard(
            kind: .info,
            title: "No notes yet",
            message: "Tap the plus button on the top right to create your first secure note."
        )
    }

    private var notesList: some View {
        LazyVStack(spacing: AppTheme.Spacing.md) {
            ForEach(viewModel.notes) { note in
                Button {
                    selectedNoteForEditor = note
                } label: {
                    SecureNoteRow(note: note)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        selectedNoteForEditor = note
                    } label: {
                        Label("Open", systemImage: "doc.text")
                    }

                    Button {
                        notePendingRename = note
                        renameText = note.title
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    Button {
                        notePendingExport = note
                        isShowingExportDialog = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        notePendingDelete = note
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func createAndOpenNote() {
        guard let note = viewModel.createNoteForEditing() else {
            return
        }

        selectedNoteForEditor = note
    }
}

private struct SecureNoteRow: View {
    let note: SecureNote

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(note.title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.mutedText)
            }

            if !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(note.content)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .lineLimit(2)
            } else {
                Text("Empty note")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.mutedText)
            }

            Text("Updated \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.mutedText)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        }
    }
}