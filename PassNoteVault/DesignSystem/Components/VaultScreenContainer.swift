//
//  VaultScreenContainer.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct VaultScreenContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack {
                    content
                        .frame(maxWidth: AppTheme.Layout.maxContentWidth)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.xl)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}