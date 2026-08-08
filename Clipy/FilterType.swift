//
//  FilterType.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

enum FilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case text = "Texts"
    case image = "Images"
    case file = "Files"
    case pinned = "Pinned"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "folder"
        case .pinned: return "pin.fill"
        }
    }
}
