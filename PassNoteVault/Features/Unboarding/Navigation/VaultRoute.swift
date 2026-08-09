//
//  VaultRoute.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

enum VaultRoute: Hashable {
    case createPassword
    case review
}

struct VaultOnboardingCoordinator: View {
    let onVaultCreated: () -> Void
    var onVaultRestored: () -> Void

    @StateObject private var setupViewModel = VaultSetupViewModel()
    @State private var path: [VaultRoute] = []
    @State private var creationErrorMessage: String?
    @State private var isShowingRestore = false

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onCreateVault: {
                    path.append(.createPassword)
                },
                onImportBackup: {
                    isShowingRestore = true
                }
            )
            .navigationDestination(for: VaultRoute.self) { route in
                switch route {
                case .createPassword:
                    CreateVaultPasswordView(viewModel: setupViewModel) {
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
        .sheet(isPresented: $isShowingRestore) {
            FullVaultRestoreView {
                onVaultRestored()
            }
        }
    }

    private func createSecureVault() {
        guard setupViewModel.canContinueFromPassword else {
            creationErrorMessage = "Please complete all required vault setup steps."
            return
        }

        do {
            try VaultDatabase.shared.create(masterPassword: setupViewModel.masterPassword)
            VaultDatabase.shared.close()
            setupViewModel.clearSensitiveInputs()

            creationErrorMessage = nil
            onVaultCreated()

        } catch {
            print("Vault creation failed:", error)
            creationErrorMessage = "Could not create encrypted vault. Please try again."
        }
    }
}
