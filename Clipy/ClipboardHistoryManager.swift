//
//  ClipboardHistoryManager.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import Foundation
import AppKit
import SwiftUI
import Observation

/// Coordinates clipboard history in-memory state, deduplication, pinning, and item lifecycle.
@Observable
final class ClipboardHistoryManager {
    var items: [ClipboardHistoryItem] = []
    
    var maxLimit: Int = 50 {
        didSet {
            UserDefaults.standard.set(maxLimit, forKey: "clipy_max_limit")
            trimHistory()
        }
    }
    
    let storage: ClipboardStorageProtocol
    private let monitor: ClipboardMonitoringProtocol
    var lastCopiedItem: ClipboardHistoryItem?
    
    init(
        storage: ClipboardStorageProtocol = DiskClipboardStorage(),
        monitor: ClipboardMonitoringProtocol = ClipboardMonitor()
    ) {
        self.storage = storage
        self.monitor = monitor
        
        let savedLimit = UserDefaults.standard.integer(forKey: "clipy_max_limit")
        self.maxLimit = savedLimit > 0 ? savedLimit : 50
        self.items = storage.loadHistory()
        
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.onClipboardChanged = { [weak self] newItem in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleNewClipboardItem(newItem)
            }
        }
        monitor.startMonitoring()
    }
    
    private func handleNewClipboardItem(_ item: ClipboardHistoryItem) {
        if let lastCopied = lastCopiedItem {
            if isSameItem(item, lastCopied) {
                if item.type == .image, let tempURL = item.fileURL {
                    try? FileManager.default.removeItem(at: tempURL)
                }
                moveItemToTop(lastCopied)
                self.lastCopiedItem = nil
                return
            }
        }
        
        if let duplicateIndex = findDuplicateIndex(of: item) {
            let duplicate = items[duplicateIndex]
            if item.type == .image, let tempURL = item.fileURL {
                try? FileManager.default.removeItem(at: tempURL)
            }
            moveItemToTop(duplicate)
            return
        }
        
        var finalItem = item
        if item.type == .image, let tempURL = item.fileURL {
            if let cachedPath = storage.cacheImage(from: tempURL) {
                finalItem = ClipboardHistoryItem(
                    id: item.id,
                    type: .image,
                    imagePath: cachedPath,
                    timestamp: item.timestamp,
                    sourceAppName: item.sourceAppName
                )
            }
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        withAnimation {
            items.insert(finalItem, at: 0)
        }
        
        trimHistory()
        storage.saveHistory(items)
    }
    
    private func isSameItem(_ a: ClipboardHistoryItem, _ b: ClipboardHistoryItem) -> Bool {
        if a.type != b.type { return false }
        switch a.type {
        case .text: return a.stringValue == b.stringValue
        case .file: return a.fileURL == b.fileURL
        case .image: return Date().timeIntervalSince(b.timestamp) < 2.0
        }
    }
    
    private func findDuplicateIndex(of item: ClipboardHistoryItem) -> Int? {
        items.firstIndex { existing in
            if existing.type != item.type { return false }
            switch item.type {
            case .text: return existing.stringValue == item.stringValue
            case .file: return existing.fileURL == item.fileURL
            case .image: return false
            }
        }
    }
    
    private func moveItemToTop(_ item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        withAnimation {
            var updated = items.remove(at: index)
            updated = ClipboardHistoryItem(
                id: updated.id,
                type: updated.type,
                stringValue: updated.stringValue,
                fileName: updated.fileName,
                fileURL: updated.fileURL,
                imagePath: updated.imagePath,
                timestamp: Date(),
                isPinned: updated.isPinned,
                sourceAppName: updated.sourceAppName
            )
            items.insert(updated, at: 0)
        }
        storage.saveHistory(items)
    }
    
    private func trimHistory() {
        guard items.count > maxLimit else { return }
        
        var indexesToRemove: [Int] = []
        for i in (0..<items.count).reversed() {
            if items.count - indexesToRemove.count <= maxLimit { break }
            if !items[i].isPinned { indexesToRemove.append(i) }
        }
        
        guard !indexesToRemove.isEmpty else { return }
        
        withAnimation {
            for index in indexesToRemove {
                let item = items[index]
                if let imagePath = item.imagePath {
                    storage.deleteCachedImage(at: imagePath)
                }
                items.remove(at: index)
            }
        }
        storage.saveHistory(items)
    }
}
