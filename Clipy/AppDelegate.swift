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
        guard !AppEnvironment.isRunningTests else { return }
        LaunchAtLoginService.enableOnFirstLaunch()
        PastePermission.promptIfNeeded()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // History saves are debounced onto a background queue; write the last one before exiting.
        ClipboardHistoryManager.shared?.storage.flush()
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
