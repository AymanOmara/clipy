//
//  PasteStack.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation
import Observation

/// What the panel asks `PanelManager` to paste into the previously active app.
enum PasteRequest {
    /// A history item; `plainText` drops rich formatting.
    case item(ClipboardHistoryItem, plainText: Bool)
    /// Arbitrary text: a transformed item, an expanded snippet or recognised image text.
    case text(String)
}

/// A queue of items pasted one at a time with the "Paste Next" shortcut, e.g. to fill a form.
@Observable
final class PasteStack {
    static let shared = PasteStack()

    private(set) var entries: [ClipboardHistoryItem] = []
    
    init() {}

    var isEmpty: Bool { entries.isEmpty }

    func contains(_ item: ClipboardHistoryItem) -> Bool {
        entries.contains { $0.id == item.id }
    }

    func position(of item: ClipboardHistoryItem) -> Int? {
        entries.firstIndex { $0.id == item.id }.map { $0 + 1 }
    }

    func toggle(_ item: ClipboardHistoryItem) {
        if contains(item) {
            entries.removeAll { $0.id == item.id }
        } else {
            entries.append(item)
        }
    }

    /// Removes and returns the next entry still present in `history` (its current version),
    /// dropping entries that were deleted, trimmed or expired since they were queued.
    func popNext(from history: [ClipboardHistoryItem]) -> ClipboardHistoryItem? {
        while !entries.isEmpty {
            let entry = entries.removeFirst()
            if let current = history.first(where: { $0.id == entry.id }) { return current }
        }
        return nil
    }
    
    /// Drops entries that no longer exist in `history`.
    func prune(keeping history: [ClipboardHistoryItem]) {
        let ids = Set(history.map(\.id))
        entries.removeAll { !ids.contains($0.id) }
    }

    func clear() {
        entries.removeAll()
    }
}
