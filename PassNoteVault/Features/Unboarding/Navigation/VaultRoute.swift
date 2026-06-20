//
//  VaultRoute.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

enum VaultRoute: Hashable {
    case createPassword
    case createPassphrase
    case review
}

struct VaultOnboardingCoordinator: View {
    let onVaultCreated: () -> Void

    @StateObject private var setupViewModel = VaultSetupViewModel()
    @State private var path: [VaultRoute] = []
    @State private var creationErrorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onCreateVault: {
                    path.append(.createPassword)
                },
                onImportBackup: {
                    // Backup import flow will be added later.
                }
            )
            .navigationDestination(for: VaultRoute.self) { route in
                switch route {
                case .createPassword:
                    CreateVaultPasswordView(viewModel: setupViewModel) {
                        path.append(.createPassphrase)
                    }

                case .createPassphrase:
                    CreateVaultPassphraseView(viewModel: setupViewModel) {
                        path.append(.review)
                    }

                case .review:
                    CreateVaultReviewView(
                        viewModel: setupViewModel,
                        errorMessage: creationErrorMessage
                    ) {
                        createSecureVault()
                    }
                }
            }
        }
        .tint(AppTheme.Colors.accent)
    }

    private func createSecureVault() {
        guard setupViewModel.canContinueFromPassword,
              setupViewModel.hasSavedPassphrase
        else {
            creationErrorMessage = "Please complete all required vault setup steps."
            return
        }

        do {
            try VaultDatabase.shared.open(passphrase: setupViewModel.masterPassword)

            /*
             Later:
             - Do not use recovery passphrase for DB open directly.
             - Use it for encrypted backup recovery/import.
             - Add KDF: master password + salt -> SQLCipher key.
             */

            VaultDatabase.shared.close()

            creationErrorMessage = nil
            onVaultCreated()

        } catch {
            print("Vault creation failed:", error)
            creationErrorMessage = "Could not create encrypted vault. Please try again."
        }
    }
}
