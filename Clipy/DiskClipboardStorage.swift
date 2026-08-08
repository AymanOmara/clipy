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
    private let bundleIdentifier = "self.Clipy"
    private let historyFileName = "ClipboardHistory.json"
    
    private var appSupportDirectory: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(bundleIdentifier)
    }
    
    private var cachesDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(bundleIdentifier)
    }
    
    init() {
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        guard let appDir = appSupportDirectory, let cacheDir = cachesDirectory else { return }
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    func loadHistory() -> [ClipboardHistoryItem] {
        guard let fileURL = appSupportDirectory?.appendingPathComponent(historyFileName),
              fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([ClipboardHistoryItem].self, from: data)
            return decoded
        } catch {
            print("[DiskClipboardStorage] Failed to load clipboard history: \(error)")
            return []
        }
    }
    
    func saveHistory(_ items: [ClipboardHistoryItem]) {
        guard let fileURL = appSupportDirectory?.appendingPathComponent(historyFileName) else { return }
        
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[DiskClipboardStorage] Failed to save clipboard history: \(error)")
        }
    }
    
    func cacheImage(from tempURL: URL) -> String? {
        guard let cacheDir = cachesDirectory else { return nil }
        
        let relativePath = "images/\(UUID().uuidString).png"
        let destinationURL = cacheDir.appendingPathComponent(relativePath)
        
        // Ensure images subdirectory exists
        try? fileManager.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        do {
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            return relativePath
        } catch {
            print("[DiskClipboardStorage] Failed to cache image: \(error)")
            return nil
        }
    }
    
    func deleteCachedImage(at relativePath: String) {
        guard let cacheDir = cachesDirectory else { return }
        let fileURL = cacheDir.appendingPathComponent(relativePath)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearAllCachedImages() {
        guard let cacheDir = cachesDirectory else { return }
        let imagesDir = cacheDir.appendingPathComponent("images")
        try? fileManager.removeItem(at: imagesDir)
        try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    func loadImage(from relativePath: String) -> NSImage? {
        guard let cacheDir = cachesDirectory else { return nil }
        let fullPath = cacheDir.appendingPathComponent(relativePath)
        return NSImage(contentsOf: fullPath)
    }
}
