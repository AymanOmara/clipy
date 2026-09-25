//
//  SettingsShortcutsSection.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

struct SettingsShortcutsSection: View {
    var body: some View {
        Form {
            Section {
                row("Show or hide Clipy", detail: "Opens the clipboard panel from any app.", action: .togglePanel)
                row("Paste next from stack", detail: "Pastes queued items one at a time.", action: .pasteNextInStack)
            } header: {
                Text("Global Shortcuts")
            } footer: {
                Text("Click a shortcut, then press the new keys. Esc cancels, ⌫ restores the default.")
                    .settingsFooter()
            }

            Section("In the Clipboard Panel") {
                keyRow("Paste selected item", keys: "↩")
                keyRow("Paste as plain text", keys: "⌥↩")
                keyRow("Add to or remove from paste stack", keys: "⇧↩")
                keyRow("Quick Look", keys: "Space")
                keyRow("Paste item 1–9", keys: "1 … 9")
                keyRow("Move between items", keys: "← →")
                keyRow("Close", keys: "Esc")
            }
        }
    }

    private func row(_ title: String, detail: String, action: HotkeyAction) -> some View {
        LabeledContent {
            HotkeyRecorderView(action: action)
        } label: {
            Text(title)
            Text(detail)
        }
    }

    private func keyRow(_ title: String, keys: String) -> some View {
        LabeledContent(title) {
            Text(keys)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}
