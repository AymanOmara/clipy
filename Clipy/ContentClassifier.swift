//
//  ContentClassifier.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation
import SwiftUI

/// What a copied piece of text looks like, used for card rendering and filtering.
nonisolated enum ContentKind: String, Codable, Sendable {
    case plain
    case url
    case email
    case phone
    case color
    case code

    var iconName: String {
        switch self {
        case .plain: return "doc.text"
        case .url: return "link"
        case .email: return "envelope"
        case .phone: return "phone"
        case .color: return "paintpalette"
        case .code: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

/// Pure, side-effect-free detection of the semantic kind of copied text.
nonisolated enum ContentClassifier {
    private static let hexColor = try! NSRegularExpression(pattern: "^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")
    private static let rgbColor = try! NSRegularExpression(pattern: "^rgba?\\(\\s*\\d{1,3}\\s*,\\s*\\d{1,3}\\s*,\\s*\\d{1,3}\\s*(,\\s*(0|1|0?\\.\\d+)\\s*)?\\)$", options: .caseInsensitive)
    private static let email = try! NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$", options: .caseInsensitive)
    private static let phone = try! NSRegularExpression(pattern: "^\\+?[0-9][0-9 ()\\-.]{6,18}[0-9]$")
    private static let codeSignals = [
        "func ", "let ", "var ", "const ", "import ", "return ", "class ", "struct ", "def ",
        "=> ", "->", "{\n", "};", "</", "#include", "public ", "private ", "if (", "for ("
    ]

    static func classify(_ raw: String) -> ContentKind {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count < 20_000 else { return .plain }

        if !text.contains(where: \.isWhitespace) {
            if matches(hexColor, text) || matches(rgbColor, text) { return .color }
            if matches(email, text) { return .email }
            if isWebURL(text) { return .url }
        }
        if matches(rgbColor, text) { return .color }
        if matches(phone, text), text.filter(\.isNumber).count >= 7 { return .phone }
        if looksLikeCode(text) { return .code }
        return .plain
    }

    static func isWebURL(_ text: String) -> Bool {
        guard let url = URL(string: text), let scheme = url.scheme?.lowercased() else { return false }
        return ["http", "https"].contains(scheme) && url.host != nil
    }

    /// Parses `#RGB`, `#RRGGBB`, `#RRGGBBAA` and `rgb()/rgba()` into a SwiftUI color.
    static func color(from raw: String) -> Color? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") {
            var hex = String(text.dropFirst())
            if hex.count == 3 || hex.count == 4 { hex = hex.map { "\($0)\($0)" }.joined() }
            guard let value = UInt64(hex, radix: 16) else { return nil }
            let hasAlpha = hex.count == 8
            let r = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
            let g = Double((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
            let b = Double((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
            let a = hasAlpha ? Double(value & 0xFF) / 255 : 1
            return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        }
        let numbers = text
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
            .compactMap(Double.init)
        guard numbers.count >= 3 else { return nil }
        return Color(.sRGB, red: numbers[0] / 255, green: numbers[1] / 255, blue: numbers[2] / 255,
                     opacity: numbers.count > 3 ? numbers[3] : 1)
    }

    private static func looksLikeCode(_ text: String) -> Bool {
        let signals = codeSignals.filter { text.contains($0) }.count
        let symbolRatio = Double(text.filter { "{}[]();=<>".contains($0) }.count) / Double(max(text.count, 1))
        let lines = text.split(separator: "\n")
        let indented = lines.filter { $0.hasPrefix("    ") || $0.hasPrefix("\t") }.count
        return signals >= 2 || (signals >= 1 && symbolRatio > 0.04) || (lines.count > 2 && indented * 2 >= lines.count && symbolRatio > 0.02)
    }

    private static func matches(_ regex: NSRegularExpression, _ text: String) -> Bool {
        regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
