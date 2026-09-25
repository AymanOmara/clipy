//
//  SettingsWindowController.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa
import SwiftUI

/// Manages the presentation and lifecycle of the Preferences panel.
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSPanel?
    
    func showSettings(with historyManager: ClipboardHistoryManager) {
        if let existing = window {
            existing.orderFrontRegardless()
            existing.makeKey()
            NSApp.activate()
            return
        }
        
        let settingsPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        settingsPanel.title = "Clipy Settings"
        settingsPanel.toolbarStyle = .unified
        settingsPanel.isReleasedWhenClosed = false
        settingsPanel.hidesOnDeactivate = false
        settingsPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        settingsPanel.delegate = self
        
        // A hosting controller lets the split view's sidebar and pane title use the window toolbar.
        let hostingController = NSHostingController(rootView: SettingsView().environment(historyManager))
        hostingController.sceneBridgingOptions = [.title, .toolbars]
        settingsPanel.contentViewController = hostingController
        settingsPanel.setContentSize(NSSize(width: 720, height: 540))
        settingsPanel.center()
        self.window = settingsPanel
        
        settingsPanel.orderFrontRegardless()
        settingsPanel.makeKey()
        NSApp.activate()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false // Prevents AppKit window destruction / app termination
    }
    
    func isPointInsideSettingsWindow(_ point: NSPoint) -> Bool {
        guard let window = window, window.isVisible else { return false }
        return NSPointInRect(point, window.frame)
    }
}
