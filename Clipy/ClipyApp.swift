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
        let manager = ClipboardHistoryManager()
        self._historyManager = State(initialValue: manager)
        PanelManager.shared.setup(historyManager: manager)
    }
    
    var body: some Scene {
        #if os(macOS)
        Settings {
            EmptyView()
        }
        #else
        WindowGroup {
            ContentView()
                .environment(historyManager)
        }
        #endif
    }
}
