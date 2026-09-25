//
//  FilterType.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

/// A tab in the panel's filter bar: a built-in category, the snippet library, or a user pinboard.
enum FilterType: Hashable, Identifiable {
    case all
    case text
    case image
    case file
    case link
    case color
    case code
    case pinned
    case snippets
    case pinboard(UUID)

    static let builtIn: [FilterType] = [.all, .text, .image, .file, .link, .color, .code, .pinned, .snippets]

    var id: String {
        if case let .pinboard(boardID) = self { return boardID.uuidString }
        return title
    }

    var title: String {
        switch self {
        case .all: return "All"
        case .text: return "Texts"
        case .image: return "Images"
        case .file: return "Files"
        case .link: return "Links"
        case .color: return "Colors"
        case .code: return "Code"
        case .pinned: return "Pinned"
        case .snippets: return "Snippets"
        case .pinboard: return "Pinboard"
        }
    }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "folder"
        case .link: return "link"
        case .color: return "paintpalette"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .pinned: return "pin.fill"
        case .snippets: return "text.badge.star"
        case .pinboard: return "square.stack.fill"
        }
    }

    func matches(_ item: ClipboardHistoryItem) -> Bool {
        switch self {
        case .all: return true
        case .text: return item.type == .text && ![.url, .color, .code].contains(item.kind)
        case .image: return item.type == .image
        case .file: return item.type == .file
        case .link: return item.kind == .url
        case .color: return item.kind == .color
        case .code: return item.kind == .code
        case .pinned: return item.isPinned
        case .snippets: return false
        case let .pinboard(boardID): return item.pinboardID == boardID
        }
    }
}
