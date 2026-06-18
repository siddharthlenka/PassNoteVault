//
//  AppButtonKind.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

enum AppButtonKind {
    case primary
    case secondary
}

struct AppButton: View {
    let title: String
    var systemImage: String?
    var kind: AppButtonKind = .primary
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            guard isEnabled, !isLoading else { return }
            action()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .font(AppTheme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }

    private var backgroundColor: Color {
        switch kind {
        case .primary:
            return AppTheme.Colors.accent
        case .secondary:
            return AppTheme.Colors.card
        }
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary:
            return .white
        case .secondary:
            return AppTheme.Colors.primaryText
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary:
            return Color.clear
        case .secondary:
            return AppTheme.Colors.border
        }
    }
}