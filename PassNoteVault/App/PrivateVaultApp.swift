//
//  PrivateVaultApp.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct VaultRootView: View {
    @AppStorage("hasCreatedVault") private var hasCreatedVault = false

    @State private var isAuthenticated = false
    @State private var loggedInUsername = ""
    @State private var loginSuccessMessage: String?

    var body: some View {
        if isAuthenticated {
            VaultLandingView(
                username: loggedInUsername,
                onLogout: {
                    isAuthenticated = false
                    loggedInUsername = ""
                }
            )
        } else if !hasCreatedVault {
            VaultOnboardingCoordinator(
                onVaultCreated: { username in
                    hasCreatedVault = true
                    loginSuccessMessage = """
                    Account creation successful. Try using your username and password to login. Save your username and password somewhere safe for future reference.
                    """
                }
            )
        } else {
            FirstTimeLoginView(
                initialUsername: VaultCredentialStore.savedUsername ?? "",
                successMessage: loginSuccessMessage
            ) { username, password in

                guard VaultCredentialStore.validate(username: username, password: password) else {
                    return "Invalid username or password."
                }

                loggedInUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                loginSuccessMessage = nil
                isAuthenticated = true

                return nil
            }
        }
    }
}
