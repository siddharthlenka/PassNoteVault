//
//  AddPasswordView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//


import SwiftUI

struct AddPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var accountName = ""
    @State private var password = ""
    @State private var selectedLength: HexPasswordLength = .sixteen
    @State private var didCopyGeneratedPassword = false

    let onSave: (_ accountName: String, _ password: String) -> Void

    private var canSave: Bool {
        !accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    headerSection

                    VStack(spacing: AppTheme.Spacing.md) {
                        AppTextField(
                            title: "Account name",
                            placeholder: "Example: Gmail, Instagram, GitHub",
                            text: $accountName
                        )

                        AppSecureField(
                            title: "Password",
                            placeholder: "Enter or generate password",
                            text: $password
                        )
                    }

                    generatorSection

                    buttonSection
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: AppTheme.Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Add Password")
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Create a new password record for your vault.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private var generatorSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Generate random hex password")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            Picker("Password length", selection: $selectedLength) {
                ForEach(HexPasswordLength.allCases) { length in
                    Text(length.title)
                        .tag(length)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: AppTheme.Spacing.md) {
                AppButton(
                    title: "Generate Password",
                    systemImage: "wand.and.stars",
                    kind: .secondary
                ) {
                    password = SecureHexPasswordGenerator.generate(length: selectedLength)
                    didCopyGeneratedPassword = false
                }

                Button {
                    guard !password.isEmpty else { return }

                    ClipboardHelper.copy(password)
                    didCopyGeneratedPassword = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        didCopyGeneratedPassword = false
                    }
                } label: {
                    Image(systemName: didCopyGeneratedPassword ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(didCopyGeneratedPassword ? AppTheme.Colors.success : AppTheme.Colors.accent)
                        .frame(width: 54, height: 54)
                        .background(AppTheme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                                .stroke(AppTheme.Colors.border, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(password.isEmpty)
                .opacity(password.isEmpty ? 0.45 : 1)
            }

            InfoWarningCard(
                kind: .info,
                title: "Hex password",
                message: "Generated password uses hexadecimal characters: 0-9 and A-F."
            )
        }
    }

    private var buttonSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AppButton(
                title: "Save",
                systemImage: "checkmark",
                isEnabled: canSave
            ) {
                onSave(
                    accountName.trimmingCharacters(in: .whitespacesAndNewlines),
                    password
                )
                dismiss()
            }

            AppButton(
                title: "Cancel",
                systemImage: "xmark",
                kind: .secondary
            ) {
                dismiss()
            }
        }
    }
}