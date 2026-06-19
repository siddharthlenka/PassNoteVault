//
//  VaultRoute.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

enum VaultRoute: Hashable {
    case createUsername
    case createPassword
    case createPassphrase
    case review
    case firstTimeLogin
    case normalUnlock
}

struct VaultOnboardingCoordinator: View {
    let onVaultCreated: (_ username: String) -> Void

    @StateObject private var setupViewModel = VaultSetupViewModel()
    @State private var path: [VaultRoute] = []
    @State private var creationErrorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onCreateVault: {
                    path.append(.createUsername)
                },
                onImportBackup: {
                    path.append(.firstTimeLogin)
                }
            )
            .navigationDestination(for: VaultRoute.self) { route in
                switch route {
                case .createUsername:
                    CreateVaultUsernameView(viewModel: setupViewModel) {
                        path.append(.createPassword)
                    }

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

                case .firstTimeLogin:
                    FirstTimeLoginView { _, _ in
                        return "Import backup flow is not connected yet."
                    }

                case .normalUnlock:
                    FirstTimeLoginView { _, _ in
                        return "Normal unlock flow is not connected yet."
                    }
                }
            }
        }
        .tint(AppTheme.Colors.accent)
    }

    private func createSecureVault() {
        guard setupViewModel.isUsernameValid,
              setupViewModel.canContinueFromPassword,
              setupViewModel.hasSavedPassphrase
        else {
            creationErrorMessage = "Please complete all required vault setup steps."
            return
        }

        let username = setupViewModel.username.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try VaultCredentialStore.save(
                username: username,
                password: setupViewModel.masterPassword
            )

            creationErrorMessage = nil

            /*
             TODO later:
             1. Generate vault salt.
             2. Derive SQLCipher key.
             3. Create/open encrypted GRDB + SQLCipher DB.
             4. Save only safe metadata.
             5. Never store raw password in final production flow.
             */

            onVaultCreated(username)

        } catch {
            creationErrorMessage = "Could not save credentials securely. Please try again."
            print("Keychain save failed:", error)
        }
    }
}
