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
    /// The running instance, for entry points outside the SwiftUI tree (App Intents).
    private(set) static weak var shared: ClipboardHistoryManager?

    var items: [ClipboardHistoryItem] = []
    var pinboards: [Pinboard] = [] {
        didSet { storage.saveDocument(pinboards, named: Self.pinboardsFileName) }
    }
    var snippets: [Snippet] = [] {
        didSet { storage.saveDocument(snippets, named: Self.snippetsFileName) }
    }

    var maxLimit: Int = 50 {
        didSet {
            defaults.set(maxLimit, forKey: "clipy_max_limit")
            trimHistory()
        }
    }

    /// Unprotected items older than this many days are removed; 0 keeps them forever.
    var retentionDays: Int = 0 {
        didSet {
            defaults.set(retentionDays, forKey: "clipy_retention_days")
            purgeExpiredItems()
        }
    }

    static let pinboardsFileName = "Pinboards.json"
    static let snippetsFileName = "Snippets.json"

    let storage: ClipboardStorageProtocol
    private let monitor: ClipboardMonitoringProtocol
    private let defaults: UserDefaults
    private var retentionTimer: Timer?

    /// Set when Clipy itself writes to the pasteboard, so that write is not recorded as a new item.
    var lastCopiedItem: ClipboardHistoryItem?
    var lastWrittenChangeCount: Int?

    init(
        storage: ClipboardStorageProtocol = DiskClipboardStorage(),
        monitor: ClipboardMonitoringProtocol = ClipboardMonitor(),
        defaults: UserDefaults = .standard
    ) {
        self.storage = storage
        self.monitor = monitor
        self.defaults = defaults

        let savedLimit = defaults.integer(forKey: "clipy_max_limit")
        self.maxLimit = savedLimit > 0 ? savedLimit : 50
        self.retentionDays = defaults.integer(forKey: "clipy_retention_days")
        self.items = storage.loadHistory()
        self.pinboards = storage.loadDocument([Pinboard].self, named: Self.pinboardsFileName) ?? []
        self.snippets = storage.loadDocument([Snippet].self, named: Self.snippetsFileName) ?? []
        Self.shared = self

        purgeExpiredItems()
        setupMonitoring()
        retentionTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.purgeExpiredItems() }
        }
    }

    private func setupMonitoring() {
        monitor.onClipboardChanged = { [weak self] capture in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleCapture(capture)
            }
        }
        monitor.startMonitoring()
    }

    func handleCapture(_ capture: ClipboardCapture) {
        if capture.changeCount == lastWrittenChangeCount {
            if let copied = lastCopiedItem { moveItemToTop(copied) }
            lastCopiedItem = nil
            lastWrittenChangeCount = nil
            return
        }

        switch capture.content {
        case let .text(string, rtf, html):
            insertOrPromote(ClipboardHistoryItem(
                type: .text, stringValue: string,
                sourceAppName: capture.sourceAppName, sourceBundleID: capture.sourceBundleID,
                rtfData: rtf, htmlString: html
            ))
        case let .files(urls):
            guard let first = urls.first else { return }
            insertOrPromote(ClipboardHistoryItem(
                type: .file, fileName: first.lastPathComponent, fileURL: first,
                sourceAppName: capture.sourceAppName, sourceBundleID: capture.sourceBundleID,
                fileURLs: urls.count > 1 ? urls : nil
            ))
        case let .image(tiffData):
            processImage(tiffData, capture: capture)
        }
    }

    /// Hashes, encodes and OCRs the image off the main thread; dedup and insertion stay on the main actor.
    private func processImage(_ tiffData: Data, capture: ClipboardCapture) {
        let storage = self.storage
        let copiedAt = Date()
        Task { [weak self] in
            let hash = await Task.detached(priority: .userInitiated) { ImageProcessor.hash(tiffData) }.value
            guard let self, !self.promoteDuplicateImage(hash: hash) else { return }
            
            let stored = await Task.detached(priority: .userInitiated) { () -> (path: String, size: CGSize, png: Data)? in
                guard let encoded = ImageProcessor.encodePNG(tiffData: tiffData),
                      let path = storage.storeImage(pngData: encoded.png) else { return nil }
                return (path, encoded.size, encoded.png)
            }.value
            guard let stored else { return }
            
            let item = ClipboardHistoryItem(
                type: .image, imagePath: stored.path, timestamp: copiedAt,
                sourceAppName: capture.sourceAppName, sourceBundleID: capture.sourceBundleID,
                imageHash: hash, imagePixelSize: stored.size
            )
            self.insertOrPromote(item)
            guard self.items.contains(where: { $0.id == item.id }) else {
                // An identical image landed while this one was encoding; drop the unused file.
                storage.deleteCachedImage(at: stored.path)
                return
            }
            
            let text = await Task.detached(priority: .utility) { ImageProcessor.recognizeText(in: stored.png) }.value
            if let text { self.update(item.id) { $0.ocrText = text } }
        }
    }
    
    private func promoteDuplicateImage(hash: String) -> Bool {
        guard let existing = items.first(where: { $0.imageHash == hash }) else { return false }
        moveItemToTop(existing)
        return true
    }

    /// Adds a new item at the top, or moves an existing duplicate there instead.
    func insertOrPromote(_ item: ClipboardHistoryItem) {
        if let duplicate = items.first(where: { isDuplicate($0, of: item) }) {
            moveItemToTop(duplicate)
            return
        }
        // Newest first by copy time: an image that finished encoding late still sorts
        // below text copied after it.
        let index = items.firstIndex { $0.timestamp <= item.timestamp } ?? items.count
        withAnimation {
            items.insert(item, at: index)
        }
        trimHistory()
        storage.saveHistory(items)
    }

    private func isDuplicate(_ existing: ClipboardHistoryItem, of item: ClipboardHistoryItem) -> Bool {
        guard existing.type == item.type else { return false }
        switch item.type {
        case .text: return existing.stringValue == item.stringValue
        case .file: return existing.allFileURLs == item.allFileURLs
        case .image: return item.imageHash != nil && existing.imageHash == item.imageHash
        }
    }

    func moveItemToTop(_ item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation {
            var updated = items.remove(at: index)
            updated.timestamp = Date()
            items.insert(updated, at: 0)
        }
        storage.saveHistory(items)
    }

    /// Mutates one item in place and persists the change.
    func update(_ id: UUID, _ change: (inout ClipboardHistoryItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        change(&items[index])
        storage.saveHistory(items)
    }

    func trimHistory() {
        var unprotectedBudget = items.count - maxLimit
        guard unprotectedBudget > 0 else { return }
        let idsToRemove = items.reversed().filter { item in
            guard unprotectedBudget > 0, !item.isProtected else { return false }
            unprotectedBudget -= 1
            return true
        }.map(\.id)
        removeItems(withIDs: Set(idsToRemove))
    }

    func purgeExpiredItems(now: Date = Date()) {
        guard retentionDays > 0 else { return }
        let cutoff = now.addingTimeInterval(-Double(retentionDays) * 86_400)
        let expired = items.filter { !$0.isProtected && $0.timestamp < cutoff }.map(\.id)
        removeItems(withIDs: Set(expired))
    }

    func removeItems(withIDs ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        defer { PasteStack.shared.prune(keeping: items) }
        withAnimation {
            items.removeAll { item in
                guard ids.contains(item.id) else { return false }
                if let imagePath = item.imagePath { storage.deleteCachedImage(at: imagePath) }
                return true
            }
        }
        storage.saveHistory(items)
    }
}
