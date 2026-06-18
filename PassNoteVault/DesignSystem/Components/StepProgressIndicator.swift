//
//  StepProgressIndicator.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

struct StepProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Step \(currentStep) of \(totalSteps)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.mutedText)

            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? AppTheme.Colors.accent : AppTheme.Colors.border)
                        .frame(height: 5)
                }
            }
        }
    }
}