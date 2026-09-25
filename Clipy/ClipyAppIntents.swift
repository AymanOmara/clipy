//
//  ClipyAppIntents.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import AppIntents
import Foundation

enum ClipyIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notRunning
    case emptyHistory
    case snippetNotFound(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notRunning: return "Clipy is not running."
        case .emptyHistory: return "Clipy's history is empty."
        case let .snippetNotFound(name): return "No snippet named \(name)."
        }
    }
}

@MainActor
private func runningManager() throws -> ClipboardHistoryManager {
    guard let manager = ClipboardHistoryManager.shared else { throw ClipyIntentError.notRunning }
    return manager
}

/// Text form of any history item: the text itself, recognised image text, or file paths.
private func textValue(of item: ClipboardHistoryItem) -> String? {
    switch item.type {
    case .text: return item.stringValue
    case .image: return item.ocrText
    case .file: return item.allFileURLs.map(\.path).joined(separator: "\n")
    }
}

struct GetLatestClipboardItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Latest Clipboard Item"
    static let description = IntentDescription("Returns the most recent item in Clipy's history as text.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = try runningManager()
        guard let text = manager.items.lazy.compactMap(textValue(of:)).first else { throw ClipyIntentError.emptyHistory }
        return .result(value: text)
    }
}

struct SearchClipboardIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Clipboard History"
    static let description = IntentDescription("Finds history items matching a query. Supports filters such as app:, type: and date:.")

    @Parameter(title: "Query")
    var query: String

    @Parameter(title: "Limit", default: 10, inclusiveRange: (1, 100))
    var limit: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let manager = try runningManager()
        let search = SearchQuery(query)
        let matches = manager.items
            .filter { search.score($0) != nil }
            .compactMap(textValue(of:))
        return .result(value: Array(matches.prefix(limit)))
    }
}

struct SaveToClipyIntent: AppIntent {
    static let title: LocalizedStringResource = "Save Text to Clipy"
    static let description = IntentDescription("Adds text to Clipy's history, optionally into a pinboard (created if missing).")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Pinboard")
    var pinboardName: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let manager = try runningManager()
        let item = ClipboardHistoryItem(type: .text, stringValue: text, sourceAppName: "Shortcuts", sourceBundleID: "com.apple.shortcuts")
        manager.insertOrPromote(item)

        if let name = pinboardName?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
           let saved = manager.items.first(where: { $0.type == .text && $0.stringValue == text }) {
            let board = manager.pinboards.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
                ?? manager.createPinboard(named: name)
            manager.assign(saved, to: board)
        }
        return .result()
    }
}

struct GetSnippetIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Snippet"
    static let description = IntentDescription("Returns a Clipy snippet with its placeholders filled in.")

    @Parameter(title: "Snippet Name")
    var name: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let manager = try runningManager()
        guard let snippet = manager.snippets.first(where: { $0.title.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw ClipyIntentError.snippetNotFound(name)
        }
        return .result(value: manager.expandedText(for: snippet))
    }
}

struct ShowClipyIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Clipy"
    static let description = IntentDescription("Opens the Clipy clipboard panel.")

    @MainActor
    func perform() async throws -> some IntentResult {
        PanelManager.shared.showPanel()
        return .result()
    }
}

struct ClipyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLatestClipboardItemIntent(),
            phrases: ["Get latest item from \(.applicationName)"],
            shortTitle: "Latest Item",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: SearchClipboardIntent(),
            phrases: ["Search \(.applicationName) history"],
            shortTitle: "Search History",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: ShowClipyIntent(),
            phrases: ["Show \(.applicationName)"],
            shortTitle: "Show Clipy",
            systemImageName: "paperclip"
        )
    }
}
