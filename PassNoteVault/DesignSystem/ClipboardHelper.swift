//
//  ClipboardHelper.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum ClipboardHelper {
    private static var pendingClearTask: Task<Void, Never>?
    private static var lastCopiedPassword: String?

    static func copy(_ text: String) {
        copyPassword(text)
    }

    static func copyPassword(_ password: String) {
        pendingClearTask?.cancel()
        lastCopiedPassword = password
        let duration = VaultSettingsMetadata.clipboardClearDuration

        #if canImport(UIKit)
        var options: [UIPasteboard.OptionsKey: Any] = [
            .localOnly: true
        ]

        if let interval = duration.expirationInterval {
            options[.expirationDate] = Date().addingTimeInterval(interval)
        }

        UIPasteboard.general.setItems(
            [[UTTypePlainTextIdentifier as String: password]],
            options: options
        )
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(password, forType: .string)
        #endif

        if let interval = duration.expirationInterval {
            pendingClearTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

                if Task.isCancelled {
                    return
                }

                await MainActor.run {
                    clearCopiedPasswordIfUnchanged()
                }
            }
        }
    }

    static func clearCopiedPasswordWhenBackgrounded() {
        guard VaultSettingsMetadata.clipboardClearDuration == .whenAppGoesToBackground else {
            return
        }

        clearCopiedPasswordIfUnchanged()
    }

    static func clearCopiedPasswordIfUnchanged() {
        guard let lastCopiedPassword else {
            return
        }

        #if canImport(UIKit)
        if UIPasteboard.general.string == lastCopiedPassword {
            UIPasteboard.general.string = ""
        }
        #elseif canImport(AppKit)
        if NSPasteboard.general.string(forType: .string) == lastCopiedPassword {
            NSPasteboard.general.clearContents()
        }
        #endif

        self.lastCopiedPassword = nil
        pendingClearTask?.cancel()
        pendingClearTask = nil
    }

    private static let UTTypePlainTextIdentifier = "public.utf8-plain-text"
}
