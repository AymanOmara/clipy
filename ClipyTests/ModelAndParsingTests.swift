//
//  ModelAndParsingTests.swift
//  ClipyTests
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation
import Testing
@testable import Clipy

struct LegacyHistoryTests {
    /// History written by the first release (before rich text, pinboards and kinds existed).
    @Test func decodesHistoryFromFirstRelease() throws {
        let json = """
        [
          {"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","type":"text","stringValue":"https://apple.com",
           "timestamp":812032045.37,"isPinned":true,"sourceAppName":"Safari"},
          {"id":"7F9619FF-8B86-D011-B42D-00C04FC964FF","type":"file","fileName":"a.pdf",
           "fileURL":"file:///tmp/a.pdf","timestamp":812032000,"isPinned":false}
        ]
        """
        let items = try JSONDecoder().decode([ClipboardHistoryItem].self, from: Data(json.utf8))
        #expect(items.count == 2)
        #expect(items[0].kind == .url)
        #expect(items[0].isPinned)
        #expect(items[0].pinboardID == nil)
        #expect(items[1].allFileURLs == [URL(fileURLWithPath: "/tmp/a.pdf")])
    }

    @Test func roundTripsNewFields() throws {
        var item = ClipboardHistoryItem(type: .text, stringValue: "#ff0000", rtfData: Data([1, 2]), htmlString: "<p>")
        item.pinboardID = UUID()
        item.ocrText = "hello"
        let decoded = try JSONDecoder().decode(ClipboardHistoryItem.self, from: JSONEncoder().encode(item))
        #expect(decoded == item)
        #expect(decoded.kind == .color)
    }
}

struct ContentClassifierTests {
    @Test(arguments: [
        ("https://example.com/path?q=1", ContentKind.url),
        ("#1e90ff", .color),
        ("#FFF", .color),
        ("rgb(10, 20, 30)", .color),
        ("rgba(10,20,30,0.5)", .color),
        ("someone@example.com", .email),
        ("+1 (555) 123-4567", .phone),
        ("func greet() -> String {\n    return \"hi\"\n}", .code),
        ("const x = 5;\nlet y = x + 1;", .code),
        ("Just a normal sentence.", .plain),
        ("2024", .plain),
        ("example.com", .plain)
    ])
    func classifies(_ text: String, _ expected: ContentKind) {
        #expect(ContentClassifier.classify(text) == expected)
    }

    @Test func parsesColors() {
        #expect(ContentClassifier.color(from: "#000000") != nil)
        #expect(ContentClassifier.color(from: "rgb(1,2,3)") != nil)
        #expect(ContentClassifier.color(from: "#zzz") == nil)
    }
}

struct SearchQueryTests {
    private let safariLink = ClipboardHistoryItem(type: .text, stringValue: "https://swift.org/documentation", sourceAppName: "Safari")
    private let xcodeCode = ClipboardHistoryItem(type: .text, stringValue: "let value = compute()", sourceAppName: "Xcode")
    private let pinnedNote = ClipboardHistoryItem(type: .text, stringValue: "Meeting notes", isPinned: true, sourceAppName: "Notes")

    @Test func parsesFiltersAndTerms() {
        let query = SearchQuery("app:safari type:link is:pinned date:today board:work hello")
        #expect(query.app == "safari")
        #expect(query.types == ["link"])
        #expect(query.flags == ["pinned"])
        #expect(query.dateRange == .today)
        #expect(query.board == "work")
        #expect(query.terms == ["hello"])
    }

    @Test func filtersByAppTypeAndFlag() {
        #expect(SearchQuery("app:safari").score(safariLink) != nil)
        #expect(SearchQuery("app:safari").score(xcodeCode) == nil)
        #expect(SearchQuery("type:code").score(xcodeCode) != nil)
        #expect(SearchQuery("type:link").score(xcodeCode) == nil)
        #expect(SearchQuery("is:pinned").score(pinnedNote) != nil)
        #expect(SearchQuery("is:pinned").score(safariLink) == nil)
    }

    @Test func filtersByDate() {
        let old = ClipboardHistoryItem(type: .text, stringValue: "old", timestamp: Date().addingTimeInterval(-3 * 86_400))
        #expect(SearchQuery("date:today").score(old) == nil)
        #expect(SearchQuery("date:week").score(old) != nil)
    }

    @Test func substringBeatsFuzzy() throws {
        let exact = try #require(SearchQuery.score(term: "meet", in: pinnedNote))
        let fuzzy = try #require(SearchQuery.score(term: "mtng", in: pinnedNote))
        #expect(exact > fuzzy)
    }

    @Test func fuzzyMatchIsInOrderOnly() {
        #expect(SearchQuery.fuzzyScore("mtg", in: "meeting") != nil)
        #expect(SearchQuery.fuzzyScore("gtm", in: "meeting") == nil)
        #expect(SearchQuery.fuzzyScore("m", in: "meeting") == nil)
    }

    @Test func searchesRecognisedImageText() {
        var image = ClipboardHistoryItem(type: .image, imagePath: "images/x.png")
        image.ocrText = "Invoice total 42"
        #expect(SearchQuery("invoice").score(image) != nil)
    }
}

struct TextTransformTests {
    @Test func caseAndWhitespace() {
        #expect(TextTransform.uppercase.apply(to: "abc") == "ABC")
        #expect(TextTransform.trimWhitespace.apply(to: "  a  \n  b  ") == "a\nb")
        #expect(TextTransform.collapseWhitespace.apply(to: "a \n\t b") == "a b")
    }

    @Test func json() {
        #expect(TextTransform.minifyJSON.apply(to: "{ \"a\" : [1, 2] }") == "{\"a\":[1,2]}")
        #expect(TextTransform.formatJSON.apply(to: "{\"b\":1,\"a\":2}") == "{\n  \"a\" : 2,\n  \"b\" : 1\n}")
        #expect(TextTransform.formatJSON.apply(to: "not json") == nil)
    }

    @Test func encodings() {
        #expect(TextTransform.urlEncode.apply(to: "a b&c") == "a%20b%26c")
        #expect(TextTransform.urlDecode.apply(to: "a%20b%26c") == "a b&c")
        #expect(TextTransform.base64Encode.apply(to: "hello") == "aGVsbG8=")
        #expect(TextTransform.base64Decode.apply(to: "aGVsbG8=") == "hello")
        #expect(TextTransform.base64Decode.apply(to: "***") == nil)
    }
}

struct SnippetExpanderTests {
    @Test func expandsPlaceholders() {
        let date = Date(timeIntervalSince1970: 0)
        let result = SnippetExpander.expand("Hi {clipboard} on {date}", now: date, clipboard: "Sam")
        #expect(result == "Hi Sam on \(date.formatted(date: .abbreviated, time: .omitted))")
    }

    @Test func doesNotReexpandInsertedClipboardText() {
        #expect(SnippetExpander.expand("{clipboard}", clipboard: "{date} {uuid}") == "{date} {uuid}")
    }
    
    @Test func leavesUnknownTokensAlone() {
        #expect(SnippetExpander.expand("{unknown}") == "{unknown}")
    }
}

struct KeyComboTests {
    @Test func displaysModifiersInMacOrder() {
        #expect(KeyCombo.defaultToggle.displayString == "⇧⌘V")
        #expect(KeyCombo.defaultPasteNext.displayString == "⌃⌘V")
    }
}

@MainActor
struct PasteStackTests {
    @Test func popNextSkipsItemsNoLongerInHistory() {
        let stack = PasteStack()
        let kept = ClipboardHistoryItem(type: .text, stringValue: "kept")
        let deleted = ClipboardHistoryItem(type: .text, stringValue: "deleted")
        stack.toggle(deleted)
        stack.toggle(kept)
        #expect(stack.popNext(from: [kept])?.id == kept.id)
        #expect(stack.isEmpty)
    }
}

struct TextFileExporterTests {
    @Test func namesFileFromFirstLine() {
        #expect(TextFileExporter.fileName(for: "  Meeting notes for Monday\nsecond line") == "Meeting notes for Monday.txt")
    }

    @Test func stripsCharactersNotAllowedInFileNames() {
        #expect(TextFileExporter.fileName(for: "a/b:c?d*\"e\"") == "a b c d e.txt")
    }

    @Test func shortensLongFirstLineAtWordBoundary() {
        let name = TextFileExporter.fileName(for: String(repeating: "word ", count: 30))
        #expect(name.count <= 54)
        #expect(name.hasSuffix("word.txt"))
    }

    @Test func fallsBackToDatedNameWhenNothingUsable() {
        #expect(TextFileExporter.fileName(for: "  \n///").hasPrefix("Clipy Text "))
    }

    @Test func writesUTF8ContentAndClearsOldExports() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipyTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = try TextFileExporter.export("first", to: directory)
        let text = "مرحبا بالعالم 👋\nsecond line"
        let url = try TextFileExporter.export(text, to: directory)

        #expect(url.lastPathComponent == "مرحبا بالعالم 👋.txt")
        #expect(try String(contentsOf: url, encoding: .utf8) == text)
        #expect(!FileManager.default.fileExists(atPath: first.path))
    }
}
