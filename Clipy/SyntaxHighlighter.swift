//
//  SyntaxHighlighter.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// Language-agnostic highlighting for code previews: comments, strings, numbers and common keywords.
enum SyntaxHighlighter {
    private static let keywords = [
        "func", "let", "var", "const", "import", "return", "class", "struct", "enum", "protocol", "extension",
        "if", "else", "for", "while", "switch", "case", "def", "function", "public", "private", "static",
        "async", "await", "try", "catch", "throw", "new", "true", "false", "nil", "null", "self", "this",
        "final", "void", "int", "string", "interface", "type", "export", "from", "package", "fun", "val"
    ]

    private static let rules: [(NSRegularExpression, Color)] = [
        (try! NSRegularExpression(pattern: "\\b(\(keywords.joined(separator: "|")))\\b"), .pink),
        (try! NSRegularExpression(pattern: "\\b\\d+(\\.\\d+)?\\b"), .orange),
        (try! NSRegularExpression(pattern: "\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'"), .green),
        (try! NSRegularExpression(pattern: "//[^\\n]*|#(?!include)[^\\n{]*$|/\\*[\\s\\S]*?\\*/", options: .anchorsMatchLines), .gray)
    ]

    static func highlight(_ code: String) -> AttributedString {
        var attributed = AttributedString(code)
        attributed.foregroundColor = .primary.opacity(0.85)
        let range = NSRange(code.startIndex..., in: code)
        // Later rules win, so strings override keywords inside them and comments override everything.
        for (regex, color) in rules {
            for match in regex.matches(in: code, range: range) {
                guard let stringRange = Range(match.range, in: code),
                      let attributedRange = Range(stringRange, in: attributed) else { continue }
                attributed[attributedRange].foregroundColor = color
            }
        }
        return attributed
    }
}
