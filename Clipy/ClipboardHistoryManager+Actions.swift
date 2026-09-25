//
//  ClipboardHistoryManager+Actions.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation
import AppKit
import SwiftUI

extension ClipboardHistoryManager {
    /// Write item content back to the system pasteboard.
    /// With `plainTextOnly`, rich text formatting (RTF/HTML) is left out.
    /// Returns false (leaving the clipboard untouched) when the item's content is no longer available.
    @discardableResult
    func copyToClipboard(_ item: ClipboardHistoryItem, plainTextOnly: Bool = false) -> Bool {
        let pasteboard = NSPasteboard.general
        let image = item.type == .image ? loadImage(for: item) : nil
        switch item.type {
        case .text where item.stringValue == nil, .file where item.allFileURLs.isEmpty, .image where image == nil:
            return false
        default:
            break
        }
        pasteboard.clearContents()

        switch item.type {
        case .text:
            if let string = item.stringValue {
                var types: [NSPasteboard.PasteboardType] = [.string]
                let rtf = plainTextOnly ? nil : item.rtfData
                let html = plainTextOnly ? nil : item.htmlString
                if rtf != nil { types.append(.rtf) }
                if html != nil { types.append(.html) }
                pasteboard.declareTypes(types, owner: nil)
                pasteboard.setString(string, forType: .string)
                if let rtf { pasteboard.setData(rtf, forType: .rtf) }
                if let html { pasteboard.setString(html, forType: .html) }
            }
        case .file:
            pasteboard.writeObjects(item.allFileURLs.map { $0 as NSURL })
        case .image:
            if let image { pasteboard.writeObjects([image]) }
        }
        lastCopiedItem = item
        lastWrittenChangeCount = pasteboard.changeCount
        return true
    }

    /// Write arbitrary text (transformed items, snippets, OCR results); it is recorded as a new item.
    func copyText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Delete a single history item and clean up storage
    func deleteItem(_ item: ClipboardHistoryItem) {
        removeItems(withIDs: [item.id])
    }

    /// Toggle item pinned state
    func togglePin(for item: ClipboardHistoryItem) {
        withAnimation {
            update(item.id) { $0.isPinned.toggle() }
        }
    }

    /// Clear history items
    func clearHistory(includePinned: Bool = false) {
        if includePinned {
            withAnimation { items.removeAll() }
            PasteStack.shared.clear()
            storage.clearAllCachedImages()
            storage.saveHistory(items)
        } else {
            removeItems(withIDs: Set(items.filter { !$0.isProtected }.map(\.id)))
        }
    }

    /// Resolve image thumbnail through the storage service
    func loadImage(for item: ClipboardHistoryItem) -> NSImage? {
        guard let imagePath = item.imagePath else { return nil }
        return storage.loadImage(from: imagePath)
    }

    // MARK: - Pinboards

    @discardableResult
    func createPinboard(named name: String) -> Pinboard {
        let color = Pinboard.palette[pinboards.count % Pinboard.palette.count]
        let board = Pinboard(name: name, colorName: color)
        pinboards.append(board)
        return board
    }

    func renamePinboard(_ board: Pinboard, to name: String) {
        guard let index = pinboards.firstIndex(where: { $0.id == board.id }) else { return }
        pinboards[index].name = name
    }

    /// Deletes the board; its items return to regular history.
    func deletePinboard(_ board: Pinboard) {
        pinboards.removeAll { $0.id == board.id }
        for item in items where item.pinboardID == board.id {
            update(item.id) { $0.pinboardID = nil }
        }
        trimHistory()
    }

    func assign(_ item: ClipboardHistoryItem, to board: Pinboard?) {
        withAnimation {
            update(item.id) { $0.pinboardID = board?.id }
        }
    }

    func pinboard(for item: ClipboardHistoryItem) -> Pinboard? {
        guard let id = item.pinboardID else { return nil }
        return pinboards.first { $0.id == id }
    }

    // MARK: - Snippets

    func saveSnippet(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
        } else {
            snippets.append(snippet)
        }
    }

    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
    }

    func saveAsSnippet(_ item: ClipboardHistoryItem) {
        guard let text = item.stringValue else { return }
        saveSnippet(Snippet(title: item.displayTitle, content: text))
    }

    /// Snippet text with placeholders filled in, using the current clipboard for `{clipboard}`.
    func expandedText(for snippet: Snippet) -> String {
        SnippetExpander.expand(snippet.content, clipboard: NSPasteboard.general.string(forType: .string))
    }
}
