//
//  ClipyApp.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import SwiftUI

@main
struct ClipyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var historyManager: ClipboardHistoryManager
    
    init() {
        if AppEnvironment.isRunningTests {
            self._historyManager = State(initialValue: AppEnvironment.makeTestHostManager())
            return
        }
        let manager = ClipboardHistoryManager()
        self._historyManager = State(initialValue: manager)
        PanelManager.shared.setup(historyManager: manager)
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
