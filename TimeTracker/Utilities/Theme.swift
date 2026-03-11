//
//  Theme.swift
//  TimeTracker
//
//  Adaptive color definitions for light & dark mode.
//

import SwiftUI

enum Theme {
    // MARK: - Accent

    static let accent = Color(red: 0.90, green: 0.35, blue: 0.45)
    static let accentButton = Color(red: 0.85, green: 0.25, blue: 0.35)
    static let green = Color(red: 0.20, green: 0.72, blue: 0.45)
    static let blue = Color(red: 0.30, green: 0.55, blue: 0.90)
    static let destructive = Color(red: 0.85, green: 0.20, blue: 0.25)

    // MARK: - Adaptive backgrounds

    /// Main window / panel background
    static func panelBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.14)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    /// Bottom bar background
    static func barBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.09, green: 0.10, blue: 0.12)
            : Color(red: 0.93, green: 0.93, blue: 0.94)
    }

    /// Subtle surface tint (column headers, totals footer, day strip)
    static func surfaceTint(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.02)
            : Color.black.opacity(0.03)
    }

    /// Separator lines
    static func separator(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.08)
    }

    /// Row hover background
    static func hoverBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.03)
            : Color.black.opacity(0.04)
    }

    /// Banner backgrounds
    static func deleteBannerBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.18, green: 0.14, blue: 0.15)
            : Color(red: 0.98, green: 0.94, blue: 0.94)
    }

    static func addBannerBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.12, green: 0.17, blue: 0.14)
            : Color(red: 0.93, green: 0.98, blue: 0.94)
    }

    static func codeBannerBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.12, green: 0.14, blue: 0.18)
            : Color(red: 0.93, green: 0.95, blue: 0.99)
    }

    static func todayBannerBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.16, green: 0.12, blue: 0.13)
            : Color(red: 0.98, green: 0.95, blue: 0.96)
    }

    // MARK: - Hero gradients

    static func heroActiveGradient(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark ? [
            Color(red: 0.75, green: 0.18, blue: 0.28).opacity(0.5),
            Color(red: 0.45, green: 0.10, blue: 0.18).opacity(0.7),
            Color(red: 0.20, green: 0.08, blue: 0.12)
        ] : [
            Color(red: 0.88, green: 0.30, blue: 0.40).opacity(0.7),
            Color(red: 0.78, green: 0.22, blue: 0.32).opacity(0.85),
            Color(red: 0.68, green: 0.18, blue: 0.28).opacity(0.9)
        ]
    }

    static func heroIdleGradient(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark ? [
            Color(red: 0.22, green: 0.23, blue: 0.25).opacity(0.5),
            Color(red: 0.16, green: 0.17, blue: 0.19).opacity(0.7),
            Color(red: 0.12, green: 0.13, blue: 0.15)
        ] : [
            Color(red: 0.92, green: 0.92, blue: 0.94),
            Color(red: 0.88, green: 0.88, blue: 0.90),
            Color(red: 0.85, green: 0.85, blue: 0.87)
        ]
    }

    /// Play/pause circle background when idle
    static func heroButtonIdle(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.12)
            : Color.black.opacity(0.08)
    }

    // MARK: - Text colors (adaptive)

    /// Primary text on the main panel
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.85) : .black.opacity(0.85)
    }

    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.5) : .black.opacity(0.45)
    }

    static func textTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
    }

    static func textQuaternary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.2) : .black.opacity(0.2)
    }

    /// Hero text (always white in dark, dark in light active, grey-ish in light idle)
    static func heroText(_ scheme: ColorScheme, isRunning: Bool) -> Color {
        if scheme == .dark { return .white }
        return isRunning ? .white : .black.opacity(0.85)
    }

    static func heroSubtext(_ scheme: ColorScheme, isRunning: Bool) -> Color {
        if scheme == .dark { return .white.opacity(0.8) }
        return isRunning ? .white.opacity(0.85) : .black.opacity(0.6)
    }

    static func heroMutedText(_ scheme: ColorScheme, isRunning: Bool) -> Color {
        if scheme == .dark { return .white.opacity(0.3) }
        return isRunning ? .white.opacity(0.5) : .black.opacity(0.3)
    }

    // MARK: - Banner button

    static func bannerSecondaryButton(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }

    static func bannerSecondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.7)
            : Color.black.opacity(0.6)
    }

    static func bannerPrimaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .white
    }

    // MARK: - Misc

    /// Empty state icon circle
    static func emptyStateCircle(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.05)
    }

    static func emptyStateIcon(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.25)
            : Color.black.opacity(0.25)
    }
}
