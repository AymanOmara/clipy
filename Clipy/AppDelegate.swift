//
//  AppDelegate.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa
import SwiftUI

/// Manages application-level lifecycle events and prevents auto-termination.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep Clipy running in the background as a menu bar / overlay utility
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        PanelManager.shared.showPanel()
        return true
    }
}
