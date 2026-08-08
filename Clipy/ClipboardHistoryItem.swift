//
//  ClipboardHistoryItem.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import Foundation
import AppKit
import SwiftUI

enum ClipboardItemType: String, Codable, CaseIterable {
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

struct ClipboardHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ClipboardItemType
    let stringValue: String?
    let fileName: String?
    let fileURL: URL?
    let imagePath: String? // Relative path inside caches directory
    let timestamp: Date
    var isPinned: Bool
    let sourceAppName: String?
    
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    init(
        id: UUID = UUID(),
        type: ClipboardItemType,
        stringValue: String? = nil,
        fileName: String? = nil,
        fileURL: URL? = nil,
        imagePath: String? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceAppName: String? = nil
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
    }
    
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
            return fileName ?? "Copied File"
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
            return "Image asset"
        case .file:
            if let path = fileURL?.path {
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
