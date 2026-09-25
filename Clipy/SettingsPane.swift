//
//  SettingsPane.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// The sidebar entries of the Settings window.
enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case shortcuts
    case gestures
    case privacy
    case snippets
    case pinboards
    case storage
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .shortcuts: return "Shortcuts"
        case .gestures: return "Gestures"
        case .privacy: return "Privacy"
        case .snippets: return "Snippets"
        case .pinboards: return "Pinboards"
        case .storage: return "Storage"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape.fill"
        case .shortcuts: return "command"
        case .gestures: return "hand.draw.fill"
        case .privacy: return "hand.raised.fill"
        case .snippets: return "text.badge.star"
        case .pinboards: return "square.stack.fill"
        case .storage: return "internaldrive.fill"
        case .about: return "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .general, .about: return .gray
        case .shortcuts: return .blue
        case .gestures: return .purple
        case .privacy: return .indigo
        case .snippets: return .orange
        case .pinboards: return .pink
        case .storage: return .green
        }
    }

    /// Sections after which the sidebar leaves a gap, grouping related panes.
    var endsGroup: Bool { self == .privacy || self == .pinboards }
}

/// System Settings–style rounded-square icon.
struct SettingsPaneIcon: View {
    let pane: SettingsPane

    var body: some View {
        Image(systemName: pane.symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(pane.tint.gradient)
            )
    }
}
