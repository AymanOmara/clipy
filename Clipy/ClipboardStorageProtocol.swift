//
//  ClipboardStorageProtocol.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation
import AppKit

/// Protocol defining persistence operations for clipboard items and media assets.
protocol ClipboardStorageProtocol: AnyObject, Sendable {
    /// Loads persisted clipboard history items from storage.
    func loadHistory() -> [ClipboardHistoryItem]

    /// Persists clipboard history items; implementations may coalesce and write in the background.
    func saveHistory(_ items: [ClipboardHistoryItem])

    /// Writes any pending history save immediately (called on quit).
    func flush()

    /// Writes PNG bytes to the image cache and returns the relative path. Safe to call off the main thread.
    nonisolated func storeImage(pngData: Data) -> String?

    /// Deletes a cached image file by its relative path.
    func deleteCachedImage(at relativePath: String)

    /// Clears all cached images stored on disk.
    func clearAllCachedImages()

    /// Deletes cached images that no history item references; returns bytes freed.
    @discardableResult
    func removeOrphanedImages(referenced: Set<String>) -> Int64

    /// Total bytes used by the image cache.
    func cacheSizeInBytes() -> Int64

    /// Resolves an image path to an NSImage if available.
    func loadImage(from relativePath: String) -> NSImage?

    /// Absolute URL of a cached image, for previews and sharing.
    func imageURL(for relativePath: String) -> URL?

    /// Generic JSON persistence for small companion documents (snippets, pinboards).
    func loadDocument<T: Decodable>(_ type: T.Type, named name: String) -> T?
    func saveDocument<T: Encodable>(_ value: T, named name: String)
}
