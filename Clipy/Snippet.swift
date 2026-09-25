//
//  Snippet.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation

/// A saved text template, kept apart from history and never trimmed.
nonisolated struct Snippet: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var content: String

    init(id: UUID = UUID(), title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
}

/// Expands `{placeholder}` tokens in snippet content at paste time.
nonisolated enum SnippetExpander {
    static let placeholders: [(token: String, description: String)] = [
        ("{date}", "Today's date"),
        ("{time}", "Current time"),
        ("{datetime}", "Date and time"),
        ("{weekday}", "Day of the week"),
        ("{clipboard}", "Current clipboard text"),
        ("{uuid}", "A new random UUID")
    ]

    private static let tokenPattern = try! NSRegularExpression(pattern: "\\{(date|time|datetime|weekday|clipboard|uuid)\\}")
    
    /// Replaces placeholders in a single pass, so inserted text (e.g. clipboard contents
    /// that happen to contain `{date}`) is never expanded again.
    static func expand(_ template: String, now: Date = Date(), clipboard: String? = nil) -> String {
        let date = now.formatted(date: .abbreviated, time: .omitted)
        let time = now.formatted(date: .omitted, time: .shortened)
        let replacements: [String: String] = [
            "date": date,
            "time": time,
            "datetime": "\(date) \(time)",
            "weekday": now.formatted(.dateTime.weekday(.wide)),
            "clipboard": clipboard ?? "",
            "uuid": UUID().uuidString
        ]
        var result = ""
        var cursor = template.startIndex
        for match in tokenPattern.matches(in: template, range: NSRange(template.startIndex..., in: template)) {
            guard let whole = Range(match.range, in: template), let name = Range(match.range(at: 1), in: template) else { continue }
            result += template[cursor..<whole.lowerBound]
            result += replacements[String(template[name])] ?? String(template[whole])
            cursor = whole.upperBound
        }
        return result + template[cursor...]
    }
}
