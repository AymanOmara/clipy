//
//  TestDoubles.swift
//  ClipyTests
//
//  Created by Ayman Omara on 25/09/2026.
//

import AppKit
@testable import Clipy

/// Storage that keeps everything in memory and records what was saved.
@MainActor
final class InMemoryStorage: ClipboardStorageProtocol {
    var history: [ClipboardHistoryItem]
    var documents: [String: Data] = [:]
    private(set) var deletedImages: [String] = []
    private(set) var saveCount = 0

    init(history: [ClipboardHistoryItem] = []) {
        self.history = history
    }

    func loadHistory() -> [ClipboardHistoryItem] { history }

    func saveHistory(_ items: [ClipboardHistoryItem]) {
        history = items
        saveCount += 1
    }

    func flush() {}

    nonisolated func storeImage(pngData: Data) -> String? { "images/\(UUID().uuidString).png" }

    func deleteCachedImage(at relativePath: String) { deletedImages.append(relativePath) }

    func clearAllCachedImages() {}

    func removeOrphanedImages(referenced: Set<String>) -> Int64 { 0 }

    func cacheSizeInBytes() -> Int64 { 0 }

    func loadImage(from relativePath: String) -> NSImage? { nil }

    func imageURL(for relativePath: String) -> URL? { nil }

    func loadDocument<T: Decodable>(_ type: T.Type, named name: String) -> T? {
        documents[name].flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    func saveDocument<T: Encodable>(_ value: T, named name: String) {
        documents[name] = try? JSONEncoder().encode(value)
    }
}

/// Monitor driven by the test: `emit` delivers a capture as if it had been copied.
@MainActor
final class FakeMonitor: ClipboardMonitoringProtocol {
    var onClipboardChanged: ((ClipboardCapture) -> Void)?
    private var changeCount = 1000

    func startMonitoring() {}
    func stopMonitoring() {}

    func capture(_ content: ClipboardCapture.Content, app: String = "TestApp", changeCount: Int? = nil) -> ClipboardCapture {
        self.changeCount += 1
        return ClipboardCapture(content: content, sourceAppName: app, sourceBundleID: "test.\(app)", changeCount: changeCount ?? self.changeCount)
    }
}

@MainActor
func makeManager(history: [ClipboardHistoryItem] = [], maxLimit: Int = 50) -> (ClipboardHistoryManager, InMemoryStorage, FakeMonitor) {
    let storage = InMemoryStorage(history: history)
    let monitor = FakeMonitor()
    let defaults = UserDefaults(suiteName: "ClipyTests.\(UUID().uuidString)")!
    defaults.set(maxLimit, forKey: "clipy_max_limit")
    let manager = ClipboardHistoryManager(storage: storage, monitor: monitor, defaults: defaults)
    return (manager, storage, monitor)
}
