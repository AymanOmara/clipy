import SwiftUI

@main
struct ClipyApp: App {
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
