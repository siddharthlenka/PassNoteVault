//
//  VaultLandingView.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 18/06/26.
//


import SwiftUI

enum VaultHomeRoute: Hashable {
    case passwords
    case notes
    case settings
}

struct VaultLandingView: View {
    let onLockVault: () -> Void

    var body: some View {
        NavigationStack {
            VaultScreenContainer {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    headerSection

                    VStack(spacing: AppTheme.Spacing.md) {
                        NavigationLink(value: VaultHomeRoute.passwords) {
                            VaultModuleCard(
                                icon: "person.crop.circle.badge.key",
                                title: "Passwords",
                                message: "Store account names and passwords securely."
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: VaultHomeRoute.notes) {
                            VaultModuleCard(
                                icon: "note.text",
                                title: "Notes",
                                message: "Create private notes inside your encrypted vault."
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: VaultHomeRoute.settings) {
                            VaultModuleCard(
                                icon: "gearshape.fill",
                                title: "Settings",
                                message: "Manage vault preferences, backup, and security."
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    AppButton(
                        title: "Lock Vault",
                        systemImage: "lock.fill",
                        kind: .secondary,
                        action: onLockVault
                    )
                }
            }
            .navigationDestination(for: VaultHomeRoute.self) { route in
                switch route {
                case .passwords:
                    PasswordVaultView()

                case .notes:
                    SecureNotesView()

                case .settings:
                    SecuritySettingsView()
                }
            }
        }
        .tint(AppTheme.Colors.accent)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Vault Unlocked")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Your private offline vault is ready.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }
}

private struct VaultModuleCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentSoft)
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(message)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
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

private struct PlaceholderVaultSectionView: View {
    let title: String
    let message: String

    var body: some View {
        VaultScreenContainer {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                Text(title)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                InfoWarningCard(
                    kind: .info,
                    title: "Coming later",
                    message: message
                )
            }
        }
        .navigationTitle(title)
    }
}
