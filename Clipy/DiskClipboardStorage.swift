//
//  DiskClipboardStorage.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation
import AppKit

/// Concrete implementation of `ClipboardStorageProtocol` managing persistence on the local disk.
final class DiskClipboardStorage: ClipboardStorageProtocol {
    private let fileManager = FileManager.default
    private let historyFileName = "ClipboardHistory.json"
    private let appSupportDirectory: URL?
    nonisolated private let cachesDirectory: URL?

    /// History encoding and writing happen here so large histories never stall the UI.
    private let writeQueue = DispatchQueue(label: "self.Clipy.storage", qos: .utility)
    private var pendingSave: DispatchWorkItem?
    private var pendingItems: [ClipboardHistoryItem]?
    private let saveDelay: TimeInterval = 0.4

    init(bundleIdentifier: String = "self.Clipy") {
        appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(bundleIdentifier)
        cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(bundleIdentifier)
        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        guard let appDir = appSupportDirectory, let cacheDir = cachesDirectory else { return }
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.createDirectory(at: cacheDir.appendingPathComponent("images"), withIntermediateDirectories: true, attributes: nil)
    }

    func loadHistory() -> [ClipboardHistoryItem] {
        loadDocument([ClipboardHistoryItem].self, named: historyFileName) ?? []
    }

    func saveHistory(_ items: [ClipboardHistoryItem]) {
        pendingSave?.cancel()
        guard let fileURL = appSupportDirectory?.appendingPathComponent(historyFileName) else { return }
        pendingItems = items
        let work = DispatchWorkItem {
            Self.write(items, to: fileURL)
        }
        pendingSave = work
        writeQueue.asyncAfter(deadline: .now() + saveDelay, execute: work)
    }
    
    func flush() {
        // A cancelled work item never runs, so write the latest snapshot directly.
        pendingSave?.cancel()
        pendingSave = nil
        guard let items = pendingItems,
              let fileURL = appSupportDirectory?.appendingPathComponent(historyFileName) else { return }
        pendingItems = nil
        writeQueue.sync { Self.write(items, to: fileURL) }
    }
    
    nonisolated private static func write<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[DiskClipboardStorage] Failed to save \(url.lastPathComponent): \(error)")
        }
    }

    nonisolated func storeImage(pngData: Data) -> String? {
        guard let cacheDir = cachesDirectory else { return nil }
        let relativePath = "images/\(UUID().uuidString).png"
        do {
            try pngData.write(to: cacheDir.appendingPathComponent(relativePath), options: .atomic)
            return relativePath
        } catch {
            print("[DiskClipboardStorage] Failed to cache image: \(error)")
            return nil
        }
    }

    func deleteCachedImage(at relativePath: String) {
        guard let url = imageURL(for: relativePath) else { return }
        try? fileManager.removeItem(at: url)
    }

    func clearAllCachedImages() {
        guard let cacheDir = cachesDirectory else { return }
        let imagesDir = cacheDir.appendingPathComponent("images")
        try? fileManager.removeItem(at: imagesDir)
        try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true, attributes: nil)
    }

    @discardableResult
    func removeOrphanedImages(referenced: Set<String>) -> Int64 {
        var freed: Int64 = 0
        // Recent files may belong to an image still being processed, so leave them alone.
        let cutoff = Date().addingTimeInterval(-300)
        for (url, size, modified) in cachedImageFiles() where modified < cutoff && !referenced.contains("images/\(url.lastPathComponent)") {
            if (try? fileManager.removeItem(at: url)) != nil { freed += size }
        }
        return freed
    }

    func cacheSizeInBytes() -> Int64 {
        cachedImageFiles().reduce(0) { $0 + $1.size }
    }

    private func cachedImageFiles() -> [(url: URL, size: Int64, modified: Date)] {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        guard let imagesDir = cachesDirectory?.appendingPathComponent("images"),
              let urls = try? fileManager.contentsOfDirectory(at: imagesDir, includingPropertiesForKeys: Array(keys)) else {
            return []
        }
        return urls.map { url in
            let values = try? url.resourceValues(forKeys: keys)
            return (url, Int64(values?.fileSize ?? 0), values?.contentModificationDate ?? .distantPast)
        }
    }

    func loadImage(from relativePath: String) -> NSImage? {
        imageURL(for: relativePath).flatMap(NSImage.init(contentsOf:))
    }

    func imageURL(for relativePath: String) -> URL? {
        cachesDirectory?.appendingPathComponent(relativePath)
    }

    func loadDocument<T: Decodable>(_ type: T.Type, named name: String) -> T? {
        guard let fileURL = appSupportDirectory?.appendingPathComponent(name),
              fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: fileURL))
        } catch {
            print("[DiskClipboardStorage] Failed to load \(name): \(error)")
            return nil
        }
    }

    func saveDocument<T: Encodable>(_ value: T, named name: String) {
        guard let fileURL = appSupportDirectory?.appendingPathComponent(name) else { return }
        Self.write(value, to: fileURL)
    }
}
