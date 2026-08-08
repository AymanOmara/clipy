//
//  SettingsWindowController.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa
import SwiftUI

/// Manages the presentation and lifecycle of the Preferences window.
final class SettingsWindowController {
    private var window: NSWindow?
    
    func showSettings(with historyManager: ClipboardHistoryManager) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Clipy Preferences"
        settingsWindow.titlebarAppearsTransparent = true
        settingsWindow.titleVisibility = .visible
        settingsWindow.center()
        
        let settingsView = SettingsView(isPresented: Binding(
            get: { true },
            set: { [weak self] isPresented in
                if !isPresented {
                    self?.window?.close()
                    self?.window = nil
                }
            }
        ))
        .environment(historyManager)
        
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        self.window = settingsWindow
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: settingsWindow,
            queue: .main
        ) { [weak self] _ in
            self?.window = nil
        }
        
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
    
    func isPointInsideSettingsWindow(_ point: NSPoint) -> Bool {
        guard let window = window else { return false }
        return NSPointInRect(point, window.frame)
    }
}
