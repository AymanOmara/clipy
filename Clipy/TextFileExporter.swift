//
//  TextFileExporter.swift
//  Clipy
//
//  Created by Ayman Omara on 26/09/2026.
//

import Foundation

/// Writes a clip to a `.txt` file so long text can be sent as an attachment (WhatsApp, Zoom, …).
nonisolated enum TextFileExporter {
    static let defaultDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("Clipy Exports", isDirectory: true)

    private static let maxNameLength = 50

    /// Writes `text` as UTF-8 into `directory`, replacing earlier exports so temp files don't pile up.
    static func export(_ text: String, to directory: URL = defaultDirectory, date: Date = Date()) throws -> URL {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: directory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let url = directory.appendingPathComponent(fileName(for: text, date: date))
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// A file name built from the clip's first line, e.g. `Meeting notes for Monday.txt`.
    static func fileName(for text: String, date: Date = Date()) -> String {
        let firstLine = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines).first ?? ""
        let illegal = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.controlCharacters)
        var name = firstLine.components(separatedBy: illegal).joined(separator: " ")
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")

        if name.count > maxNameLength {
            // Cut at a word boundary when one is reasonably close to the limit.
            let prefix = String(name.prefix(maxNameLength))
            if let space = prefix.lastIndex(of: " "), prefix.distance(from: prefix.startIndex, to: space) > maxNameLength / 2 {
                name = String(prefix[..<space])
            } else {
                name = prefix
            }
        }
        name = name.trimmingCharacters(in: CharacterSet(charactersIn: ". ").union(.whitespaces))

        if name.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
            name = "Clipy Text \(formatter.string(from: date))"
        }
        return name + ".txt"
    }
}
