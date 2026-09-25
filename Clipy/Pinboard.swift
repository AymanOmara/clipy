//
//  Pinboard.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// A named collection of history items (e.g. "Work", "Code", "Replies").
nonisolated struct Pinboard: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var colorName: String

    init(id: UUID = UUID(), name: String, colorName: String = Pinboard.palette[0]) {
        self.id = id
        self.name = name
        self.colorName = colorName
    }

    static let palette = ["blue", "purple", "pink", "red", "orange", "yellow", "green", "teal", "gray"]

    var color: Color {
        switch colorName {
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "teal": return .teal
        case "gray": return .gray
        default: return .blue
        }
    }
}
