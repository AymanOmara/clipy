//
//  AppLifecycleUtility.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa

/// Utility helpers for application restart and termination.
enum AppLifecycleUtility {
    /// Relaunches a fresh instance of Clipy and terminates the current process.
    static func restartApp() {
        let bundleURL = Bundle.main.bundleURL
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundleURL.path]
        
        do {
            try process.run()
            NSApp.terminate(nil)
        } catch {
            print("[AppLifecycleUtility] Failed to relaunch app: \(error)")
        }
    }
}
