//
//  SecureNoteTitleBuilder.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//


import Foundation

enum SecureNoteTitleBuilder {
    static func makeTitle(from content: String) -> String {
        let firstNonEmptyLine = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        let title = firstNonEmptyLine ?? "Untitled Note"

        return String(title.prefix(60))
    }
}