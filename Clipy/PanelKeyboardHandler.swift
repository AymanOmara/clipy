//
//  PanelKeyboardHandler.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// Keyboard navigation for the card strip:
/// ←/→ move · ↩ paste · ⌥↩ paste as plain text · ⇧↩ add to paste stack · Space preview · ⌘E edit & paste · 1–9 quick paste.
struct PanelKeyboardHandler: ViewModifier {
    let entries: [PanelEntry]
    @Binding var selectedIndex: Int
    let paste: (PanelEntry, Bool) -> Void
    let preview: (PanelEntry) -> Void
    let edit: (PanelEntry) -> Void
    let toggleStack: (PanelEntry) -> Void

    private var selectedEntry: PanelEntry? {
        entries.indices.contains(selectedIndex) ? entries[selectedIndex] : nil
    }

    func body(content: Content) -> some View {
        content
            .onKeyPress(.leftArrow) {
                if selectedIndex > 0 { selectedIndex -= 1; return .handled }
                return .ignored
            }
            .onKeyPress(.rightArrow) {
                if selectedIndex < entries.count - 1 { selectedIndex += 1; return .handled }
                return .ignored
            }
            .onKeyPress(.return, phases: .down) { press in
                guard let entry = selectedEntry else { return .ignored }
                if press.modifiers.contains(.shift) {
                    toggleStack(entry)
                } else {
                    paste(entry, press.modifiers.contains(.option))
                }
                return .handled
            }
            .onKeyPress(.space) {
                guard let entry = selectedEntry else { return .ignored }
                preview(entry)
                return .handled
            }
            .onKeyPress("e", phases: .down) { press in
                guard press.modifiers == .command, let entry = selectedEntry else { return .ignored }
                edit(entry)
                return .handled
            }
            .onKeyPress(phases: .down) { press in
                // ⌥ changes the typed character (⌥1 → ¡), so digits only work unmodified.
                guard press.modifiers.isEmpty,
                      let char = press.characters.first, let digit = Int(String(char)), (1...9).contains(digit),
                      digit - 1 < entries.count else {
                    return .ignored
                }
                paste(entries[digit - 1], false)
                return .handled
            }
    }
}
