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
    @StateObject private var setupViewModel = VaultSetupViewModel()
    @State private var path: [VaultRoute] = []

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
                    CreateVaultReviewView(viewModel: setupViewModel) {
                        createSecureVault()
                    }

                case .firstTimeLogin:
                    FirstTimeLoginView { username, password, passphrase in
                        unlockFirstTime(
                            username: username,
                            password: password,
                            passphrase: passphrase
                        )
                    }

                case .normalUnlock:
//                    NormalUnlockView(
//                        username: setupViewModel.username,
//                        onBiometricUnlock: {
//                            unlockWithBiometrics()
//                        },
//                        onUsePassword: {
//                            path.append(.firstTimeLogin)
//                        }
//                    )
                    FirstTimeLoginView { username, password, passphrase in
                        unlockFirstTime(
                            username: username,
                            password: password,
                            passphrase: passphrase
                        )
                    }
                }
            }
        }
        .tint(AppTheme.Colors.accent)
    }

    private func createSecureVault() {
        let prototypeSecret = setupViewModel.buildPrototypeSecret()

        /*
         TODO:
         1. Generate or load vault salt.
         2. Derive final database key from prototypeSecret using KDF.
         3. Create/open GRDB + SQLCipher database.
         4. Store safe metadata in Keychain/UserDefaults as needed.
         5. Do not store master password or raw combined secret.
         */

        print("Prototype secret for development only:", prototypeSecret)

        path.append(.firstTimeLogin)
    }

    private func unlockFirstTime(
        username: String,
        password: String,
        passphrase: String
    ) {
//        let prototypeSecret = VaultSecretBuilder.buildPrototypeCombinedSecret(
//            password: password,
//            passphrase: passphrase
//        )

        /*
         TODO:
         1. Validate username against local vault metadata.
         2. Derive final SQLCipher key using same KDF config.
         3. Try opening encrypted database.
         4. If success, mark first unlock complete.
         5. If biometric enabled, store unlock material safely in Keychain.
         */

        //print("First unlock prototype secret:", prototypeSecret)

        path.append(.normalUnlock)
    }

    private func unlockWithBiometrics() {
        /*
         TODO:
         1. Use LAContext.
         2. On success, read protected unlock secret/key material from Keychain.
         3. Open SQLCipher database.
         */

        print("Biometric unlock requested")
    }
}
