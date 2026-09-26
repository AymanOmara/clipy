//
//  CardContextMenu.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI
import AppKit

/// Right-click menu for a history card.
struct CardContextMenu: View {
    @Environment(ClipboardHistoryManager.self) var manager
    @Environment(PasteStack.self) var pasteStack

    let item: ClipboardHistoryItem
    let actions: PanelActions
    let onDelete: () -> Void

    var body: some View {
        Button("Paste") { actions.paste(.item(item, plainText: false)) }
        if item.hasRichText {
            Button("Paste as Plain Text") { actions.paste(.item(item, plainText: true)) }
        }
        if let text = item.stringValue {
            transformMenu(for: text)
        }
        if let ocrText = item.ocrText {
            Button("Paste Text from Image") { actions.paste(.text(ocrText)) }
            Button("Copy Text from Image") { manager.copyText(ocrText) }
        }
        Button("Quick Look") { actions.preview(.item(item)) }

        Divider()

        if let text = item.stringValue, item.kind == .url, let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            Button("Open Link") { NSWorkspace.shared.open(url) }
        }
        if item.type == .file, !item.allFileURLs.isEmpty {
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting(item.allFileURLs) }
        }

        Button(pasteStack.contains(item) ? "Remove from Paste Stack" : "Add to Paste Stack") {
            pasteStack.toggle(item)
        }
        Button(item.isPinned ? "Unpin" : "Pin") { manager.togglePin(for: item) }
        pinboardMenu
        if item.type == .text {
            Button("Copy as .txt File") {
                if !manager.copyAsTextFile(item) { NSSound.beep() }
            }
            Button("Save as Snippet") { manager.saveAsSnippet(item) }
        }

        Divider()

        Button("Delete", role: .destructive, action: onDelete)
    }

    private func transformMenu(for text: String) -> some View {
        Menu("Paste Transformed") {
            // Previewing every transform keeps inapplicable ones disabled, but is skipped for huge clips.
            let canPreview = text.utf8.count <= 50_000
            ForEach(TextTransform.allCases) { transform in
                let preview = canPreview ? transform.apply(to: text) : nil
                Button(transform.rawValue) {
                    if let result = preview ?? transform.apply(to: text) {
                        actions.paste(.text(result))
                    } else {
                        NSSound.beep()
                    }
                }
                .disabled(canPreview && (preview == nil || preview == text))
                if transform.endsGroup { Divider() }
            }
        }
    }

    private var pinboardMenu: some View {
        Menu("Pinboard") {
            ForEach(manager.pinboards) { board in
                Button {
                    manager.assign(item, to: item.pinboardID == board.id ? nil : board)
                } label: {
                    if item.pinboardID == board.id {
                        Label(board.name, systemImage: "checkmark")
                    } else {
                        Text(board.name)
                    }
                }
            }
            if item.pinboardID != nil {
                Button("Remove from Pinboard") { manager.assign(item, to: nil) }
            }
            if !manager.pinboards.isEmpty { Divider() }
            Button("New Pinboard…") {
                guard let name = TextPrompt.run(title: "New Pinboard", message: "Items in a pinboard are kept when history is trimmed.", confirmTitle: "Create") else { return }
                manager.assign(item, to: manager.createPinboard(named: name))
            }
        }
    }
}
