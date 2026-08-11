//
//  VaultSettingsMetadata.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import Foundation

enum AutoLockDuration: String, CaseIterable, Identifiable {
    case immediately
    case thirtySeconds
    case oneMinute
    case fiveMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .immediately:
            return "Immediately"
        case .thirtySeconds:
            return "After 30 Seconds"
        case .oneMinute:
            return "After 1 Minute"
        case .fiveMinutes:
            return "After 5 Minutes"
        }
    }

    var threshold: TimeInterval {
        switch self {
        case .immediately:
            return 0
        case .thirtySeconds:
            return 30
        case .oneMinute:
            return 60
        case .fiveMinutes:
            return 300
        }
    }
}

enum ClipboardClearDuration: String, CaseIterable, Identifiable {
    case thirtySeconds
    case oneMinute
    case twoMinutes
    case whenAppGoesToBackground

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thirtySeconds:
            return "After 30 Seconds"
        case .oneMinute:
            return "After 1 Minute"
        case .twoMinutes:
            return "After 2 Minutes"
        case .whenAppGoesToBackground:
            return "When App Goes to Background"
        }
    }

    var expirationInterval: TimeInterval? {
        switch self {
        case .thirtySeconds:
            return 30
        case .oneMinute:
            return 60
        case .twoMinutes:
            return 120
        case .whenAppGoesToBackground:
            return nil
        }
    }
}

enum BackupStatus: String {
    case neverBackedUp
    case upToDate
    case updateRequired

    var title: String {
        switch self {
        case .neverBackedUp:
            return "Never Backed Up"
        case .upToDate:
            return "Up to Date"
        case .updateRequired:
            return "Backup Update Required"
        }
    }
}

enum VaultSettingsMetadata {
    static let autoLockDurationKey = "autoLockDuration"
    static let clipboardClearDurationKey = "clipboardClearDuration"
    static let lastBackgroundDateKey = "lastBackgroundDate"
    static let lastFullBackupDateKey = "lastFullBackupDate"
    static let backupUpdateRequiredKey = "backupUpdateRequired"
    static let unbackedUpPasswordChangeCountKey = "unbackedUpPasswordChangeCount"
    static let unbackedUpNoteChangeCountKey = "unbackedUpNoteChangeCount"
    static let masterPasswordChangedSinceBackupKey = "masterPasswordChangedSinceBackup"

    static var autoLockDuration: AutoLockDuration {
        get {
            let rawValue = UserDefaults.standard.string(forKey: autoLockDurationKey) ?? AutoLockDuration.immediately.rawValue
            return AutoLockDuration(rawValue: rawValue) ?? .immediately
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: autoLockDurationKey)
        }
    }

    static var clipboardClearDuration: ClipboardClearDuration {
        get {
            let rawValue = UserDefaults.standard.string(forKey: clipboardClearDurationKey) ?? ClipboardClearDuration.thirtySeconds.rawValue
            return ClipboardClearDuration(rawValue: rawValue) ?? .thirtySeconds
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: clipboardClearDurationKey)
        }
    }

    static var lastFullBackupDate: Date? {
        get {
            let timestamp = UserDefaults.standard.double(forKey: lastFullBackupDateKey)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: lastFullBackupDateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastFullBackupDateKey)
            }
        }
    }

    static var backupUpdateRequired: Bool {
        get { UserDefaults.standard.bool(forKey: backupUpdateRequiredKey) }
        set { UserDefaults.standard.set(newValue, forKey: backupUpdateRequiredKey) }
    }

    static var unbackedUpPasswordChangeCount: Int {
        get { UserDefaults.standard.integer(forKey: unbackedUpPasswordChangeCountKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: unbackedUpPasswordChangeCountKey) }
    }

    static var unbackedUpNoteChangeCount: Int {
        get { UserDefaults.standard.integer(forKey: unbackedUpNoteChangeCountKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: unbackedUpNoteChangeCountKey) }
    }

    static var masterPasswordChangedSinceBackup: Bool {
        get { UserDefaults.standard.bool(forKey: masterPasswordChangedSinceBackupKey) }
        set { UserDefaults.standard.set(newValue, forKey: masterPasswordChangedSinceBackupKey) }
    }

    static var backupStatus: BackupStatus {
        if backupUpdateRequired {
            return .updateRequired
        }

        return lastFullBackupDate == nil ? .neverBackedUp : .upToDate
    }

    static func markFullBackupCompleted(at date: Date = Date()) {
        lastFullBackupDate = date
        backupUpdateRequired = false
        unbackedUpPasswordChangeCount = 0
        unbackedUpNoteChangeCount = 0
        masterPasswordChangedSinceBackup = false
    }

    static func markBackupUpdateRequired() {
        backupUpdateRequired = true
    }

    static func markPasswordsAdded(count: Int = 1) {
        guard count > 0 else { return }
        unbackedUpPasswordChangeCount += count
        markBackupUpdateRequired()
    }

    static func markNotesAdded(count: Int = 1) {
        guard count > 0 else { return }
        unbackedUpNoteChangeCount += count
        markBackupUpdateRequired()
    }

    static func markMasterPasswordChangedSinceBackup() {
        masterPasswordChangedSinceBackup = true
        markBackupUpdateRequired()
    }

    static func recordBackgroundDate(_ date: Date = Date()) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastBackgroundDateKey)
    }

    static var lastBackgroundDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: lastBackgroundDateKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
}
