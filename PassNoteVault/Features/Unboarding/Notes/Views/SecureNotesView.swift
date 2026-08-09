//
//  SecureNotesView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import SwiftUI
import UniformTypeIdentifiers

private enum NoteExportPasswordConfirmation: Identifiable {
    case encrypted
    case plainText

    var id: String {
        switch self {
        case .encrypted:
            return "encrypted"
        case .plainText:
            return "plainText"
        }
    }

    var message: String {
        switch self {
        case .encrypted:
            return "Enter your Master Password to export this data."
        case .plainText:
            return "Enter your Master Password to export this note as readable text."
        }
    }
}

struct SecureNotesView: View {
    @StateObject private var viewModel = SecureNotesViewModel()

    @State private var selectedNoteForEditor: SecureNote?
    @State private var notePendingDelete: SecureNote?
    @State private var notePendingRename: SecureNote?
    @State private var notePendingExport: SecureNote?
    @State private var notePendingPlainTextWarning: SecureNote?
    @State private var notesPendingEncryptedExport: [SecureNote] = []
    @State private var notePendingPlainTextExport: SecureNote?

    @State private var renameText = ""
    @State private var isShowingExportDialog = false
    @State private var isSelectionMode = false
    @State private var selectedNoteIDs: Set<String> = []
    @State private var passwordConfirmation: NoteExportPasswordConfirmation?
    @State private var isShowingNoteImporter = false
    @State private var isConfirmingImportBackupPassword = false
    @State private var pendingImportData: Data?
    @State private var pendingImportedNotes: [SecureNote] = []
    @State private var isShowingImportPreview = false
    @State private var encryptedExportDocument = EncryptedExportDocument(
        data: Data(),
        contentType: .passNoteEncryptedExport
    )
    @State private var encryptedExportFilename = ExportSupport.singleNoteFilename()
    @State private var encryptedExportContentType = UTType.passNoteEncryptedExport
    @State private var isShowingNoteFileExporter = false
    @State private var exportErrorMessage: String?

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

    private var selectedNotes: [SecureNote] {
        viewModel.notes.filter { selectedNoteIDs.contains($0.id) }
    }

    private var areAllNotesSelected: Bool {
        !viewModel.notes.isEmpty && selectedNoteIDs.count == viewModel.notes.count
    }

    private var importButtonTitle: String {
        if pendingImportedNotes.count == 1 {
            return "Import Note"
        }

        return "Import \(pendingImportedNotes.count) Notes"
    }

    private var importPreviewMessage: String {
        if pendingImportedNotes.count == 1, let note = pendingImportedNotes.first {
            return "\"\(note.title)\""
        }

        return "\(pendingImportedNotes.count) notes found. Importing the same backup more than once may create duplicate entries."
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

                if let successMessage = viewModel.successMessage {
                    InfoWarningCard(
                        kind: .success,
                        title: "Import complete",
                        message: successMessage
                    )
                }

                if let exportErrorMessage {
                    InfoWarningCard(
                        kind: .warning,
                        title: "Export failed",
                        message: exportErrorMessage
                    )
                }

                if viewModel.notes.isEmpty {
                    emptyState
                } else if isSelectionMode {
                    selectionList
                    selectionActions
                } else {
                    notesList
                }
            }
        }
        .navigationTitle(isSelectionMode ? "Select Notes" : "Notes")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isSelectionMode {
                    Button("Cancel") {
                        cancelSelection()
                    }
                } else {
                    Button {
                        exportErrorMessage = nil
                        isShowingNoteImporter = true
                    } label: {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 17, weight: .semibold))
                    }

                    Button("Select") {
                        exportErrorMessage = nil
                        isSelectionMode = true
                    }
                    .disabled(viewModel.notes.isEmpty)

                    Button {
                        createAndOpenNote()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingNoteImporter,
            allowedContentTypes: [.data, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleNoteImportResult(result)
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
                    selectedNoteIDs.remove(note.id)
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
        .alert("Unencrypted Export", isPresented: Binding(
            get: { notePendingPlainTextWarning != nil },
            set: { isPresented in
                if !isPresented {
                    notePendingPlainTextWarning = nil
                }
            }
        )) {
            Button("Cancel", role: .cancel) {
                notePendingPlainTextWarning = nil
            }

            Button("Continue", role: .destructive) {
                notePendingPlainTextExport = notePendingPlainTextWarning
                notePendingPlainTextWarning = nil
                DispatchQueue.main.async {
                    passwordConfirmation = .plainText
                }
            }
        } message: {
            Text("This creates a readable text file that is not protected by encryption. Anyone with access to this file can read its contents.")
        }
        .confirmationDialog(
            "Export Note",
            isPresented: $isShowingExportDialog,
            titleVisibility: .visible
        ) {
            Button("Export Encrypted (.pnnote)") {
                if let note = notePendingExport {
                    notesPendingEncryptedExport = [note]
                    encryptedExportFilename = ExportSupport.singleNoteFilename()
                    DispatchQueue.main.async {
                        passwordConfirmation = .encrypted
                    }
                }
            }

            Button("Export Unencrypted (.txt)") {
                notePendingPlainTextWarning = notePendingExport
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose an export format for this note.")
        }
        .sheet(item: $passwordConfirmation) { confirmation in
            MasterPasswordConfirmationView(
                title: "Confirm Master Password",
                message: confirmation.message
            ) { masterPassword in
                switch confirmation {
                case .encrypted:
                    return prepareEncryptedNoteExport(masterPassword: masterPassword)
                case .plainText:
                    return preparePlainTextNoteExport(masterPassword: masterPassword)
                }
            }
        }
        .sheet(isPresented: $isConfirmingImportBackupPassword) {
            MasterPasswordConfirmationView(
                title: "Backup Password",
                message: "Enter the Master Password that was used when this backup was created.",
                passwordTitle: "Backup Password",
                passwordPlaceholder: "Enter backup password"
            ) { backupPassword in
                decryptPendingNoteImport(backupPassword: backupPassword)
            }
        }
        .alert("Import Notes", isPresented: $isShowingImportPreview) {
            Button("Cancel", role: .cancel) {
                clearNoteImportState()
            }

            Button(importButtonTitle) {
                viewModel.importNotes(pendingImportedNotes)
                clearNoteImportState()
            }
        } message: {
            Text(importPreviewMessage)
        }
        .fileExporter(
            isPresented: $isShowingNoteFileExporter,
            document: encryptedExportDocument,
            contentType: encryptedExportContentType,
            defaultFilename: encryptedExportFilename
        ) { result in
            if case .failure = result {
                exportErrorMessage = "The note export could not be saved."
            }
        }
        .onAppear {
            viewModel.loadNotes()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(isSelectionMode ? "Select Notes" : "Secure Notes")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(isSelectionMode ? "Choose notes to include in one encrypted export." : "Create private notes stored inside your encrypted vault.")
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

    private var selectionList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Button {
                toggleSelectAll()
            } label: {
                Label(
                    areAllNotesSelected ? "Deselect All" : "Select All",
                    systemImage: areAllNotesSelected ? "minus.circle" : "checkmark.circle"
                )
                .font(AppTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.accent)
            }
            .buttonStyle(.plain)

            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.notes) { note in
                    Toggle(isOn: selectionBinding(for: note)) {
                        SecureNoteRow(note: note)
                    }
                    .toggleStyle(.switch)
                }
            }
        }
    }

    private var selectionActions: some View {
        AppButton(
            title: "Export \(selectedNoteIDs.count)",
            systemImage: "lock.doc",
            isEnabled: !selectedNoteIDs.isEmpty
        ) {
            guard !selectedNotes.isEmpty else {
                exportErrorMessage = "Select at least one note to export."
                return
            }

            notesPendingEncryptedExport = selectedNotes
            encryptedExportFilename = areAllNotesSelected ?
                ExportSupport.allNotesFilename() :
                ExportSupport.selectedNotesFilename(count: selectedNotes.count)
            exportErrorMessage = nil
            passwordConfirmation = .encrypted
        }
    }

    private func createAndOpenNote() {
        guard let note = viewModel.createNoteForEditing() else {
            return
        }

        selectedNoteForEditor = note
    }

    private func selectionBinding(for note: SecureNote) -> Binding<Bool> {
        Binding(
            get: {
                selectedNoteIDs.contains(note.id)
            },
            set: { isSelected in
                if isSelected {
                    selectedNoteIDs.insert(note.id)
                } else {
                    selectedNoteIDs.remove(note.id)
                }
            }
        )
    }

    private func toggleSelectAll() {
        if areAllNotesSelected {
            selectedNoteIDs.removeAll()
        } else {
            selectedNoteIDs = Set(viewModel.notes.map(\.id))
        }
    }

    private func cancelSelection() {
        selectedNoteIDs.removeAll()
        isSelectionMode = false
    }

    private func handleNoteImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                return
            }

            switch url.pathExtension.lowercased() {
            case "pnnote":
                try ImportSupport.validateExtension(for: url, allowedExtensions: ["pnnote"])
                pendingImportData = try ImportSupport.readFileData(from: url)
                isConfirmingImportBackupPassword = true

            case "txt":
                try ImportSupport.validateExtension(for: url, allowedExtensions: ["txt"])
                let data = try ImportSupport.readFileData(from: url)
                let importedNote = try ImportSupport.plaintextImportedNote(from: data)
                if let note = viewModel.createImportedPlainTextNoteForEditing(importedNote) {
                    selectedNoteForEditor = note
                }

            default:
                throw ImportSupportError.unsupportedFileType
            }

            exportErrorMessage = nil
        } catch {
            exportErrorMessage = ImportSupport.message(for: error)
        }
    }

    private func decryptPendingNoteImport(backupPassword: String) -> String? {
        guard let pendingImportData else {
            return "Choose a note package first."
        }

        do {
            let package = try ImportDecryptionService.decrypt(
                data: pendingImportData,
                backupPassword: backupPassword,
                expectedContentType: .notes,
                payloadType: NoteExportPayload.self
            )

            guard package.payload.payloadVersion == 1 else {
                throw ImportDecryptionError.unsupportedVersion
            }

            let importedNotes = try package.payload.notes.map(ImportSupport.secureNote(from:))
            guard !importedNotes.isEmpty else {
                throw ImportSupportError.emptyImport
            }

            pendingImportedNotes = importedNotes
            isConfirmingImportBackupPassword = false
            DispatchQueue.main.async {
                isShowingImportPreview = true
            }
            exportErrorMessage = nil
            return nil
        } catch {
            return ImportSupport.message(for: error)
        }
    }

    private func clearNoteImportState() {
        pendingImportData = nil
        pendingImportedNotes = []
        isConfirmingImportBackupPassword = false
        isShowingImportPreview = false
    }

    private func prepareEncryptedNoteExport(masterPassword: String) -> String? {
        do {
            try ExportSupport.verifyMasterPassword(masterPassword)

            let payload = NoteExportPayload(
                notes: notesPendingEncryptedExport.map(NoteExportDTO.init)
            )

            let data = try ExportEncryptionService.makeEncryptedExport(
                payload: payload,
                contentType: .notes,
                itemCount: notesPendingEncryptedExport.count,
                masterPassword: masterPassword
            )

            encryptedExportDocument = EncryptedExportDocument(
                data: data,
                contentType: .passNoteEncryptedExport
            )
            encryptedExportContentType = .passNoteEncryptedExport
            passwordConfirmation = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isShowingNoteFileExporter = true
            }
            exportErrorMessage = nil
            return nil
        } catch {
            return "Incorrect Master Password or export could not be prepared."
        }
    }

    private func preparePlainTextNoteExport(masterPassword: String) -> String? {
        guard let note = notePendingPlainTextExport else {
            return "No note selected for export."
        }

        do {
            try ExportSupport.verifyMasterPassword(masterPassword)
            encryptedExportDocument = EncryptedExportDocument(
                data: Data(note.content.utf8),
                contentType: .plainText
            )
            encryptedExportContentType = .plainText
            encryptedExportFilename = ExportSupport.plainTextNoteFilename(note)
            passwordConfirmation = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isShowingNoteFileExporter = true
            }
            exportErrorMessage = nil
            return nil
        } catch {
            return "Incorrect Master Password or export could not be prepared."
        }
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
