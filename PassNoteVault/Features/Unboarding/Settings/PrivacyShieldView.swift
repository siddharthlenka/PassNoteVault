//
//  PrivacyShieldView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import SwiftUI

extension Notification.Name {
    static let passNoteShouldAutosaveSensitiveEditors = Notification.Name("passNoteShouldAutosaveSensitiveEditors")
}

struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Pass&Note Vault")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("Vault Protected")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
        }
    }
}
