//
//  SearchQuery.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation

/// A parsed search string: free text plus `app:`, `type:`, `is:`, `date:` and `board:` filters.
nonisolated struct SearchQuery: Equatable {
    enum DateRange: String { case today, yesterday, week, month }

    var terms: [String] = []
    var app: String?
    var types: Set<String> = []
    var flags: Set<String> = []
    var dateRange: DateRange?
    var board: String?

    static let helpText = "Filters: app:safari  type:image|text|file|link|color|code|email|phone  is:pinned|rich  date:today|yesterday|week|month  board:name"

    var isEmpty: Bool {
        terms.isEmpty && app == nil && types.isEmpty && flags.isEmpty && dateRange == nil && board == nil
    }

    init(_ raw: String) {
        for token in raw.split(whereSeparator: \.isWhitespace).map({ String($0).lowercased() }) {
            let parts = token.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2, !parts[1].isEmpty else {
                terms.append(token)
                continue
            }
            switch parts[0] {
            case "app": app = parts[1]
            case "type": types.insert(parts[1])
            case "is": flags.insert(parts[1])
            case "date": dateRange = DateRange(rawValue: parts[1])
            case "board": board = parts[1]
            default: terms.append(token)
            }
        }
    }

    /// Relevance of an item for this query; nil when it does not match.
    func score(_ item: ClipboardHistoryItem, boardName: String? = nil, now: Date = Date()) -> Int? {
        if let app, !(item.sourceAppName?.lowercased().contains(app) ?? false) { return nil }
        if !types.isEmpty, !types.contains(where: { matchesType($0, item) }) { return nil }
        if flags.contains("pinned"), !item.isPinned { return nil }
        if flags.contains("rich"), !item.hasRichText { return nil }
        if let board, !(boardName?.lowercased().contains(board) ?? false) { return nil }
        if let dateRange, !matchesDate(dateRange, item.timestamp, now: now) { return nil }

        var total = 0
        for term in terms {
            guard let termScore = Self.score(term: term, in: item) else { return nil }
            total += termScore
        }
        return total
    }

    private func matchesType(_ type: String, _ item: ClipboardHistoryItem) -> Bool {
        switch type {
        case "text": return item.type == .text
        case "image", "img": return item.type == .image
        case "file": return item.type == .file
        case "link", "url": return item.kind == .url
        default: return item.kind.rawValue == type
        }
    }

    private func matchesDate(_ range: DateRange, _ date: Date, now: Date) -> Bool {
        let calendar = Calendar.current
        switch range {
        case .today: return calendar.isDate(date, inSameDayAs: now)
        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return false }
            return calendar.isDate(date, inSameDayAs: yesterday)
        case .week: return now.timeIntervalSince(date) <= 7 * 86_400
        case .month: return now.timeIntervalSince(date) <= 30 * 86_400
        }
    }

    /// Substring matches in any searchable field score highest; fuzzy (in-order letters) matches
    /// are only tried on short fields (title, file names, app) so long texts do not match everything.
    static func score(term: String, in item: ClipboardHistoryItem) -> Int? {
        let fullFields = [item.stringValue, item.ocrText].compactMap { $0?.lowercased() }
        let shortFields = ([item.displayTitle, item.sourceAppName] + item.allFileURLs.map(\.lastPathComponent))
            .compactMap { $0?.lowercased() }

        if shortFields.contains(where: { $0.hasPrefix(term) }) { return 120 }
        if (shortFields + fullFields).contains(where: { $0.contains(term) }) { return 100 }
        return shortFields.compactMap { fuzzyScore(term, in: $0) }.max()
    }

    /// Scores `needle` as an in-order subsequence of `haystack`; tighter matches score higher (1...60).
    static func fuzzyScore(_ needle: String, in haystack: String) -> Int? {
        guard needle.count >= 2 else { return nil }
        var gaps = 0
        var searchIndex = haystack.startIndex
        var previousMatch: String.Index?
        for character in needle {
            guard let found = haystack[searchIndex...].firstIndex(of: character) else { return nil }
            if let previous = previousMatch {
                gaps += haystack.distance(from: previous, to: found) - 1
            }
            previousMatch = found
            searchIndex = haystack.index(after: found)
        }
        return max(1, 60 - gaps * 3)
    }
}
