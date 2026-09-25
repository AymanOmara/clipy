//
//  ClipboardHistoryManagerTests.swift
//  ClipyTests
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation
import Testing
@testable import Clipy

@MainActor
struct ClipboardHistoryManagerTests {
    @Test func insertsNewTextAtTop() {
        let (manager, _, monitor) = makeManager()
        manager.handleCapture(monitor.capture(.text("first", rtf: nil, html: nil)))
        manager.handleCapture(monitor.capture(.text("second", rtf: nil, html: nil)))
        #expect(manager.items.map(\.stringValue) == ["second", "first"])
    }

    @Test func duplicateTextMovesToTopInsteadOfDuplicating() {
        let (manager, _, monitor) = makeManager()
        manager.handleCapture(monitor.capture(.text("a", rtf: nil, html: nil)))
        manager.handleCapture(monitor.capture(.text("b", rtf: nil, html: nil)))
        manager.handleCapture(monitor.capture(.text("a", rtf: nil, html: nil)))
        #expect(manager.items.map(\.stringValue) == ["a", "b"])
    }

    @Test func keepsRichTextRepresentations() {
        let (manager, _, monitor) = makeManager()
        let rtf = Data("{\\rtf1 bold}".utf8)
        manager.handleCapture(monitor.capture(.text("bold", rtf: rtf, html: "<b>bold</b>")))
        let item = try! #require(manager.items.first)
        #expect(item.rtfData == rtf)
        #expect(item.htmlString == "<b>bold</b>")
        #expect(item.hasRichText)
    }

    @Test func recordsEveryFileOfAMultiFileCopy() {
        let (manager, _, monitor) = makeManager()
        let urls = ["/tmp/a.txt", "/tmp/b.txt", "/tmp/c.txt"].map { URL(fileURLWithPath: $0) }
        manager.handleCapture(monitor.capture(.files(urls)))
        let item = try! #require(manager.items.first)
        #expect(item.allFileURLs == urls)
        #expect(item.displayTitle == "3 Files")

        manager.handleCapture(monitor.capture(.files(urls)))
        #expect(manager.items.count == 1)
    }

    @Test func ownPasteboardWriteIsNotRecordedAsNewItem() {
        let (manager, _, monitor) = makeManager()
        manager.handleCapture(monitor.capture(.text("old", rtf: nil, html: nil)))
        manager.handleCapture(monitor.capture(.text("new", rtf: nil, html: nil)))
        let old = manager.items[1]

        manager.lastCopiedItem = old
        manager.lastWrittenChangeCount = 42
        // Clipy's own write comes back as plain text without the rich data; it must promote, not insert.
        manager.handleCapture(monitor.capture(.text("old", rtf: nil, html: nil), changeCount: 42))
        #expect(manager.items.map(\.id) == [old.id, manager.items[1].id])
        #expect(manager.items.count == 2)
    }

    @Test func trimmingKeepsPinnedAndPinboardItems() {
        let (manager, _, monitor) = makeManager(maxLimit: 25)
        for index in 0..<25 {
            manager.handleCapture(monitor.capture(.text("item \(index)", rtf: nil, html: nil)))
        }
        let oldest = manager.items[24]
        let secondOldest = manager.items[23]
        manager.togglePin(for: oldest)
        manager.assign(secondOldest, to: manager.createPinboard(named: "Work"))

        for index in 25..<30 {
            manager.handleCapture(monitor.capture(.text("item \(index)", rtf: nil, html: nil)))
        }
        #expect(manager.items.count == 25)
        #expect(manager.items.contains { $0.id == oldest.id })
        #expect(manager.items.contains { $0.id == secondOldest.id })
        // Items 0 and 1 are protected, so the five oldest unprotected ones (2–6) were trimmed.
        #expect(!manager.items.contains { $0.stringValue == "item 2" })
        #expect(!manager.items.contains { $0.stringValue == "item 6" })
        #expect(manager.items.contains { $0.stringValue == "item 7" })
    }

    @Test func retentionRemovesOnlyOldUnprotectedItems() {
        let old = Date().addingTimeInterval(-10 * 86_400)
        let history = [
            ClipboardHistoryItem(type: .text, stringValue: "recent"),
            ClipboardHistoryItem(type: .text, stringValue: "old", timestamp: old),
            ClipboardHistoryItem(type: .text, stringValue: "old pinned", timestamp: old, isPinned: true)
        ]
        let (manager, _, _) = makeManager(history: history)
        manager.retentionDays = 7
        #expect(manager.items.compactMap(\.stringValue) == ["recent", "old pinned"])
    }

    @Test func deletingPinboardReturnsItemsToHistory() {
        let (manager, _, monitor) = makeManager()
        manager.handleCapture(monitor.capture(.text("x", rtf: nil, html: nil)))
        let board = manager.createPinboard(named: "Code")
        manager.assign(manager.items[0], to: board)
        #expect(manager.items[0].pinboardID == board.id)

        manager.deletePinboard(board)
        #expect(manager.pinboards.isEmpty)
        #expect(manager.items[0].pinboardID == nil)
    }

    @Test func pinboardsAndSnippetsPersist() {
        let (manager, storage, _) = makeManager()
        manager.createPinboard(named: "Work")
        manager.saveSnippet(Snippet(title: "Sig", content: "Thanks"))

        let reloaded = ClipboardHistoryManager(storage: storage, monitor: FakeMonitor(), defaults: UserDefaults(suiteName: "ClipyTests.reload")!)
        #expect(reloaded.pinboards.map(\.name) == ["Work"])
        #expect(reloaded.snippets.map(\.content) == ["Thanks"])
    }
}
