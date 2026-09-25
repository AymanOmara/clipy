//
//  ClipboardHistoryItem.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import Foundation
import AppKit
import SwiftUI

nonisolated enum ClipboardItemType: String, Codable, CaseIterable, Sendable {
    case text
    case image
    case file

    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "folder"
        }
    }

    var themeColor: Color {
        switch self {
        case .text: return .blue
        case .image: return .purple
        case .file: return .green
        }
    }
}

/// Every field added after the first release is optional, so older history files still decode.
nonisolated struct ClipboardHistoryItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let type: ClipboardItemType
    let stringValue: String?
    let fileName: String?
    let fileURL: URL?
    let imagePath: String? // Relative path inside caches directory
    var timestamp: Date
    var isPinned: Bool
    let sourceAppName: String?

    var sourceBundleID: String?
    /// RTF representation captured alongside the plain string, when the source app provided one.
    var rtfData: Data?
    /// HTML representation captured alongside the plain string, when the source app provided one.
    var htmlString: String?
    /// All URLs of a multi-file copy; `fileURL` keeps the first for older readers.
    var fileURLs: [URL]?
    var imageHash: String?
    var imagePixelSize: CGSize?
    /// Text recognised inside an image, used for search and "Copy Text from Image".
    var ocrText: String?
    var pinboardID: UUID?
    private var storedKind: ContentKind?

    init(
        id: UUID = UUID(),
        type: ClipboardItemType,
        stringValue: String? = nil,
        fileName: String? = nil,
        fileURL: URL? = nil,
        imagePath: String? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceAppName: String? = nil,
        sourceBundleID: String? = nil,
        rtfData: Data? = nil,
        htmlString: String? = nil,
        fileURLs: [URL]? = nil,
        imageHash: String? = nil,
        imagePixelSize: CGSize? = nil
    ) {
        self.id = id
        self.type = type
        self.stringValue = stringValue
        self.fileName = fileName
        self.fileURL = fileURL
        self.imagePath = imagePath
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceAppName = sourceAppName
        self.sourceBundleID = sourceBundleID
        self.rtfData = rtfData
        self.htmlString = htmlString
        self.fileURLs = fileURLs
        self.imageHash = imageHash
        self.imagePixelSize = imagePixelSize
        self.storedKind = type == .text ? ContentClassifier.classify(stringValue ?? "") : nil
    }

    /// Semantic kind of a text item; items saved before detection existed are classified on read.
    var kind: ContentKind {
        guard type == .text else { return .plain }
        return storedKind ?? ContentClassifier.classify(stringValue ?? "")
    }

    var allFileURLs: [URL] {
        if let urls = fileURLs, !urls.isEmpty { return urls }
        return fileURL.map { [$0] } ?? []
    }

    var hasRichText: Bool { rtfData != nil || htmlString != nil }

    /// Kept from automatic trimming: pinned or filed into a pinboard.
    var isProtected: Bool { isPinned || pinboardID != nil }

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// Short summary / title suitable for card and list display
    var displayTitle: String {
        switch type {
        case .text:
            guard let text = stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return "Empty Text"
            }
            let firstLine = text.components(separatedBy: .newlines).first ?? ""
            return firstLine.count > 60 ? String(firstLine.prefix(60)) + "..." : firstLine
        case .image:
            return "Copied Image"
        case .file:
            let count = allFileURLs.count
            return count > 1 ? "\(count) Files" : (fileName ?? "Copied File")
        }
    }

    /// Informational subtitle (character count, dimensions, or path)
    var displaySubtitle: String {
        switch type {
        case .text:
            let count = stringValue?.count ?? 0
            let lines = stringValue?.components(separatedBy: .newlines).count ?? 0
            return lines > 1 ? "\(count) chars (\(lines) lines)" : "\(count) chars"
        case .image:
            guard let size = imagePixelSize else { return "Image asset" }
            return "\(Int(size.width)) × \(Int(size.height)) px"
        case .file:
            let urls = allFileURLs
            if urls.count > 1 {
                return urls.map(\.lastPathComponent).joined(separator: ", ")
            }
            if let path = urls.first?.path {
                return path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
            }
            return "File path unavailable"
        }
    }

    /// Localized relative timestamp representation
    var displayTime: String {
        Self.relativeDateFormatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
