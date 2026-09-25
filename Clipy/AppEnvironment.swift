//
//  AppEnvironment.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import AppKit

enum AppEnvironment {
    /// True when the app is launched as the host of the unit-test bundle.
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    
    /// A history manager that never touches the user's real history, pasteboard or preferences.
    static func makeTestHostManager() -> ClipboardHistoryManager {
        let name = "self.Clipy.UnitTestHost"
        return ClipboardHistoryManager(
            storage: DiskClipboardStorage(bundleIdentifier: name),
            monitor: ClipboardMonitor(pasteboard: NSPasteboard(name: NSPasteboard.Name(name))),
            defaults: UserDefaults(suiteName: name) ?? .standard
        )
    }
}
