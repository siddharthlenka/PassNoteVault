//
//  AppTextField.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct AppTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var error: String?
    var autocorrectionDisabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(autocorrectionDisabled)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .padding(.horizontal, AppTheme.Spacing.md)
                .frame(height: 52)
                .background(AppTheme.Colors.field)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                        .stroke(error == nil ? AppTheme.Colors.border : AppTheme.Colors.danger, lineWidth: 1)
                }

            if let error, !error.isEmpty {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.danger)
            }
        }
    }
}