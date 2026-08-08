//
//  ClipboardStorageProtocol.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation
import AppKit

/// Protocol defining persistence operations for clipboard items and media assets.
protocol ClipboardStorageProtocol: AnyObject {
    /// Loads persisted clipboard history items from storage.
    func loadHistory() -> [ClipboardHistoryItem]
    
    /// Persists clipboard history items to storage.
    func saveHistory(_ items: [ClipboardHistoryItem])
    
    /// Caches a temporary image file to permanent cache storage and returns relative path.
    func cacheImage(from tempURL: URL) -> String?
    
    /// Deletes a cached image file by its relative path.
    func deleteCachedImage(at relativePath: String)
    
    /// Clears all cached images stored on disk.
    func clearAllCachedImages()
    
    /// Resolves an image path to an NSImage if available.
    func loadImage(from relativePath: String) -> NSImage?
}
