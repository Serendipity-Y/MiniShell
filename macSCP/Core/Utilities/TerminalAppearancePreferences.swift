//
//  TerminalAppearancePreferences.swift
//  MiniShell
//
//  Persisted defaults for terminal windows and rendering.
//

import AppKit
import SwiftUI

enum TerminalAppearancePreferences {
    static let windowWidthKey = "terminalAppearance.windowWidth"
    static let windowHeightKey = "terminalAppearance.windowHeight"
    static let fontSizeKey = "terminalAppearance.fontSize"
    static let foregroundColorKey = "terminalAppearance.foregroundColor"
    static let backgroundColorKey = "terminalAppearance.backgroundColor"

    static let defaultWindowWidth = 900.0
    static let defaultWindowHeight = 600.0
    static let defaultFontSize = 15.0
    static let defaultForegroundColor = "#E5E5EA"
    static let defaultBackgroundColor = "#000000"

    static let windowWidthRange = 700.0...2400.0
    static let windowHeightRange = 450.0...1600.0
    static let fontSizeRange = 10.0...28.0

    static func color(from hex: String, fallback fallbackHex: String) -> Color {
        Color(nsColor: nsColor(from: hex, fallback: fallbackHex))
    }

    static func nsColor(from hex: String, fallback fallbackHex: String) -> NSColor {
        colorComponents(from: hex)
            .map { NSColor(srgbRed: $0.red, green: $0.green, blue: $0.blue, alpha: 1) }
            ?? colorComponents(from: fallbackHex)
                .map { NSColor(srgbRed: $0.red, green: $0.green, blue: $0.blue, alpha: 1) }
            ?? .black
    }

    static func hexString(from color: Color, fallback fallbackHex: String) -> String {
        let nsColor = NSColor(color).usingColorSpace(.sRGB)
        guard let nsColor else { return fallbackHex }

        return String(
            format: "#%02X%02X%02X",
            Int((nsColor.redComponent * 255).rounded()),
            Int((nsColor.greenComponent * 255).rounded()),
            Int((nsColor.blueComponent * 255).rounded())
        )
    }

    private static func colorComponents(from hex: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let characters = value.hasPrefix("#") ? String(value.dropFirst()) : value
        guard characters.count == 6, let rgb = Int(characters, radix: 16) else { return nil }

        return (
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255
        )
    }
}
