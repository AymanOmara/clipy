//
//  FilterPill.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// A capsule tab in the header's filter bar.
struct FilterPill: View {
    let title: String
    let icon: String
    let tint: Color?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: tint == nil ? 11 : 7))
                    .foregroundColor(isSelected ? .white : (tint ?? .primary))
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? (tint ?? Color.accentColor) : Color.primary.opacity(0.04))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// Header indicator for a non-empty paste stack, with its shortcut and a clear button.
struct PasteStackStatus: View {
    @Environment(PasteStack.self) var pasteStack

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.stack.3d.up.fill")
            Text("\(pasteStack.entries.count) queued · \(HotkeySettings.shared.pasteNextCombo.displayString)")
                .lineLimit(1)
            Button {
                pasteStack.clear()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .help("Clear Paste Stack")
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.orange.opacity(0.14)))
        .help("Press \(HotkeySettings.shared.pasteNextCombo.displayString) in any app to paste the next queued item")
        .fixedSize()
    }
}
