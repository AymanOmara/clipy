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
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        settingsPanel.title = "Clipy Preferences"
        settingsPanel.titlebarAppearsTransparent = true
        settingsPanel.titleVisibility = .visible
        settingsPanel.isReleasedWhenClosed = false
        settingsPanel.hidesOnDeactivate = false
        settingsPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        settingsPanel.center()
        settingsPanel.delegate = self
        
        let settingsView = SettingsView(isPresented: Binding(
            get: { [weak self] in self?.window?.isVisible ?? true },
            set: { [weak self] isPresented in
                if !isPresented {
                    self?.window?.orderOut(nil)
                }
            }
        ))
        .environment(historyManager)
        
        settingsPanel.contentView = NSHostingView(rootView: settingsView)
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
