//
//  TextTransform.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation

/// Conversions offered by "Paste Transformed"; each returns nil when it does not apply.
nonisolated enum TextTransform: String, CaseIterable, Identifiable, Sendable {
    case uppercase = "UPPERCASE"
    case lowercase = "lowercase"
    case titleCase = "Title Case"
    case trimWhitespace = "Trim Whitespace"
    case collapseWhitespace = "Collapse to One Line"
    case formatJSON = "Format JSON"
    case minifyJSON = "Minify JSON"
    case urlEncode = "URL Encode"
    case urlDecode = "URL Decode"
    case base64Encode = "Base64 Encode"
    case base64Decode = "Base64 Decode"

    var id: String { rawValue }

    /// Transforms after which a divider is drawn in the menu.
    var endsGroup: Bool {
        [.titleCase, .collapseWhitespace, .minifyJSON, .urlDecode].contains(self)
    }

    func apply(to text: String) -> String? {
        switch self {
        case .uppercase: return text.uppercased()
        case .lowercase: return text.lowercased()
        case .titleCase: return text.capitalized
        case .trimWhitespace:
            return text
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        case .collapseWhitespace:
            return text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        case .formatJSON:
            return reencodeJSON(text, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        case .minifyJSON:
            return reencodeJSON(text, options: [.withoutEscapingSlashes])
        case .urlEncode:
            return text.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)
        case .urlDecode:
            return text.removingPercentEncoding
        case .base64Encode:
            return Data(text.utf8).base64EncodedString()
        case .base64Decode:
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = Data(base64Encoded: trimmed) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }

    private func reencodeJSON(_ text: String, options: JSONSerialization.WritingOptions) -> String? {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
              let output = try? JSONSerialization.data(withJSONObject: object, options: options.union(.fragmentsAllowed)) else {
            return nil
        }
        return String(data: output, encoding: .utf8)
    }
}

nonisolated private extension CharacterSet {
    /// Unreserved characters (RFC 3986); everything else is percent-encoded.
    static let urlQueryValueAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
