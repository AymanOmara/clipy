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
    
    /// Explains why the permission is needed, then hands off to the system prompt and Settings.
    /// Called on every launch while access is missing, so a fresh install always asks.
    static func promptIfNeeded() {
        guard !isGranted else { return }
        
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "Allow Clipy to Paste for You"
        alert.informativeText = "Clipy needs Accessibility access to paste the item you pick straight into the app you were using.\n\nTurn on Clipy in System Settings › Privacy & Security › Accessibility. Without it, items are still copied and you can press ⌘V yourself."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Grant Access")
        alert.addButton(withTitle: "Not Now")
        
        if alert.runModal() == .alertFirstButtonReturn {
            request()
            openAccessibilitySettings()
        }
    }
}
