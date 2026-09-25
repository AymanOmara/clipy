//
//  KeyCombo.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import AppKit
import Carbon

/// A global shortcut: a virtual key code plus Carbon modifier flags.
nonisolated struct KeyCombo: Codable, Equatable, Sendable {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    /// Printable name of the key, captured when the shortcut was recorded (e.g. "V", "Space").
    let keyName: String

    static let defaultToggle = KeyCombo(keyCode: UInt32(kVK_ANSI_V), carbonModifiers: UInt32(cmdKey | shiftKey), keyName: "V")
    static let defaultPasteNext = KeyCombo(keyCode: UInt32(kVK_ANSI_V), carbonModifiers: UInt32(cmdKey | controlKey), keyName: "V")

    var displayString: String {
        var result = ""
        if carbonModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + keyName
    }

    var eventModifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        return flags
    }

    /// Builds a combo from a key event; nil unless it has ⌘, ⌃ or ⌥ (or is a function key).
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }

        let name = Self.name(for: event)
        let isFunctionKey = name.hasPrefix("F") && name.count > 1
        let hasPrimaryModifier = modifiers & UInt32(cmdKey | controlKey | optionKey) != 0
        guard hasPrimaryModifier || isFunctionKey, !name.isEmpty else { return nil }
        self.init(keyCode: UInt32(event.keyCode), carbonModifiers: modifiers, keyName: name)
    }

    init(keyCode: UInt32, carbonModifiers: UInt32, keyName: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.keyName = keyName
    }

    private static let specialKeyNames: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12"
    ]

    private static func name(for event: NSEvent) -> String {
        if let special = specialKeyNames[Int(event.keyCode)] { return special }
        return (event.charactersIgnoringModifiers ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
