//
//  AppTheme.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import SwiftUI

enum AppTheme {
    enum Colors {
        static let background = Color(red: 0.025, green: 0.035, blue: 0.060)
        static let card = Color(red: 0.065, green: 0.080, blue: 0.120)
        static let elevatedCard = Color(red: 0.090, green: 0.110, blue: 0.160)

        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.68)
        static let mutedText = Color.white.opacity(0.45)

        static let accent = Color(red: 0.180, green: 0.610, blue: 1.000)
        static let accentSoft = Color(red: 0.180, green: 0.610, blue: 1.000).opacity(0.16)

        static let success = Color(red: 0.180, green: 0.820, blue: 0.560)
        static let warning = Color(red: 1.000, green: 0.700, blue: 0.220)
        static let danger = Color(red: 1.000, green: 0.320, blue: 0.360)

        static let border = Color.white.opacity(0.10)
        static let field = Color.white.opacity(0.055)
    }

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 26, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 14, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 44
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 28
    }

    enum Layout {
        static let maxContentWidth: CGFloat = 520
    }
}