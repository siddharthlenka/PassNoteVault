//
//  PassNoteVaultApp.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//

import SwiftUI

@main
struct PrivateVaultApp: App {
    init() {
        SQLCipherSmokeTest.shared.runTest()
    }
    
    var body: some Scene {
        WindowGroup {
            VaultRootView()
        }
    }
}
