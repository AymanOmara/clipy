//
//  PanelEntry.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import AppKit

/// One card in the panel: a history item or a saved snippet.
enum PanelEntry: Identifiable {
    case item(ClipboardHistoryItem)
    case snippet(Snippet)

    var id: UUID {
        switch self {
        case let .item(item): return item.id
        case let .snippet(snippet): return snippet.id
        }
    }
}

/// Source-app icons, resolved once per bundle identifier.
enum AppIconCache {
    private static var cache: [String: NSImage] = [:]

    static func icon(for bundleID: String?) -> NSImage? {
        guard let bundleID else { return nil }
        if let cached = cache[bundleID] { return cached }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache[bundleID] = icon
        return icon
    }
}

/// Modal single-line text prompt that stays above Clipy's floating panel.
enum TextPrompt {
    static func run(title: String, message: String? = nil, defaultValue: String = "", confirmTitle: String = "Save") -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message ?? ""
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = defaultValue
        alert.accessoryView = field
        alert.window.level = .statusBar + 2
        alert.window.initialFirstResponder = field

        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

/// Modal multi-line editor used to tweak text before it is pasted.
/// Return inserts a newline; ⌘↩ confirms.
enum TextEditPrompt {
    static func run(title: String, text: String, confirmTitle: String = "Paste") -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = "Press ⌘↩ to paste."
        let confirm = alert.addButton(withTitle: confirmTitle)
        confirm.keyEquivalent = "\r"
        confirm.keyEquivalentModifierMask = .command
        alert.addButton(withTitle: "Cancel")

        let scrollView = NSTextView.scrollableTextView()
        scrollView.frame = NSRect(x: 0, y: 0, width: 440, height: 240)
        scrollView.borderType = .bezelBorder
        let textView = scrollView.documentView as! NSTextView
        textView.string = text
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        alert.accessoryView = scrollView
        alert.window.level = .statusBar + 2
        alert.window.initialFirstResponder = textView

        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return textView.string.isEmpty ? nil : textView.string
    }
}
