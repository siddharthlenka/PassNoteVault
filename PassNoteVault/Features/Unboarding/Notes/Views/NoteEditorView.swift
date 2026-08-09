//
//  NoteEditorView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import SwiftUI

struct NoteEditorView: View {
    let note: SecureNote
    @ObservedObject var viewModel: SecureNotesViewModel

    @State private var content: String
    @State private var autosaveTask: Task<Void, Never>?

    init(
        note: SecureNote,
        viewModel: SecureNotesViewModel
    ) {
        self.note = note
        self.viewModel = viewModel
        self._content = State(initialValue: note.content)
    }

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                InfoWarningCard(
                    kind: .info,
                    title: "Autosave enabled",
                    message: "Your note title is generated from the first line. Changes are saved automatically."
                )

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $content)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .scrollContentBackground(.hidden)
                        .padding(AppTheme.Spacing.md)
                        .frame(minHeight: 420)
                        .background(AppTheme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                                .stroke(AppTheme.Colors.border, lineWidth: 1)
                        }

                    if content.isEmpty {
                        Text("Start writing your private note...")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.mutedText)
                            .padding(AppTheme.Spacing.lg)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .navigationTitle(SecureNoteTitleBuilder.makeTitle(from: content))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: content) { _ in
            scheduleAutosave()
        }
        .onDisappear {
            autosaveTask?.cancel()

            viewModel.saveNoteContent(
                noteID: note.id,
                content: content
            )

            viewModel.deleteNoteIfEmpty(
                noteID: note.id,
                content: content
            )
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()

        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)

            if Task.isCancelled {
                return
            }

            await MainActor.run {
                viewModel.saveNoteContent(
                    noteID: note.id,
                    content: content
                )
            }
        }
    }
}