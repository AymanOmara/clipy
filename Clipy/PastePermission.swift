//
//  PastePermission.swift
//  Clipy
//
//  Created by Ayman Omara on 24/09/2026.
//

import AppKit
import CoreGraphics

/// Wraps the macOS permission required to post synthetic key events (Accessibility).
/// Without it `CGEvent.post` is silently dropped, so auto-paste does nothing.
enum PastePermission {
    static var isGranted: Bool {
        CGPreflightPostEventAccess()
    }

    /// Shows the system prompt the first time; afterwards macOS only lists Clipy in Settings.
    @discardableResult
    static func request() -> Bool {
        CGRequestPostEventAccess()
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
