//
//  InfoWarningCardKind.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

enum InfoWarningCardKind {
    case info
    case warning
    case success
}

struct InfoWarningCard: View {
    let kind: InfoWarningCardKind
    let title: String?
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                if let title {
                    Text(title)
                        .font(AppTheme.Typography.callout.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                }

                Text(message)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.md)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        }
    }

    private var icon: String {
        switch kind {
        case .info:
            return "lock.shield"
        case .warning:
            return "exclamationmark.triangle"
        case .success:
            return "checkmark.seal"
        }
    }

    private var tint: Color {
        switch kind {
        case .info:
            return AppTheme.Colors.accent
        case .warning:
            return AppTheme.Colors.warning
        case .success:
            return AppTheme.Colors.success
        }
    }
}