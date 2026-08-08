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
    /// Write item content back to the system pasteboard
    func copyToClipboard(_ item: ClipboardHistoryItem) {
        lastCopiedItem = item
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            if let string = item.stringValue {
                pasteboard.declareTypes([.string], owner: nil)
                pasteboard.setString(string, forType: .string)
            }
        case .file:
            if let fileURL = item.fileURL {
                pasteboard.writeObjects([fileURL as NSURL])
            }
        case .image:
            if let imagePath = item.imagePath, let image = storage.loadImage(from: imagePath) {
                pasteboard.writeObjects([image])
            }
        }
    }
    
    /// Delete a single history item and clean up storage
    func deleteItem(_ item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        withAnimation {
            let removed = items.remove(at: index)
            if let imagePath = removed.imagePath {
                storage.deleteCachedImage(at: imagePath)
            }
        }
        storage.saveHistory(items)
    }
    
    /// Toggle item pinned state
    func togglePin(for item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation {
            items[index].isPinned.toggle()
        }
        storage.saveHistory(items)
    }
    
    /// Clear history items
    func clearHistory(includePinned: Bool = false) {
        withAnimation {
            if includePinned {
                storage.clearAllCachedImages()
                items.removeAll()
            } else {
                var kept: [ClipboardHistoryItem] = []
                for item in items {
                    if item.isPinned {
                        kept.append(item)
                    } else if let imagePath = item.imagePath {
                        storage.deleteCachedImage(at: imagePath)
                    }
                }
                items = kept
            }
        }
        storage.saveHistory(items)
    }
    
    /// Resolve image thumbnail through the storage service
    func loadImage(for item: ClipboardHistoryItem) -> NSImage? {
        guard let imagePath = item.imagePath else { return nil }
        return storage.loadImage(from: imagePath)
    }
}
