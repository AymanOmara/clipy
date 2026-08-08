//
//  GlobalEventMonitorManager.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa

/// Manages local and global NSEvent monitors for outside clicks, bottom-edge swipe gestures, and keyboard navigation.
final class GlobalEventMonitorManager {
    private var clickMonitorLocal: Any?
    private var clickMonitorGlobal: Any?
    private var scrollMonitorGlobal: Any?
    private var escapeMonitorLocal: Any?
    
    func setup(
        isPanelDisplayed: @escaping () -> Bool,
        onOutsideClick: @escaping () -> Void,
        onBottomScrollUp: @escaping () -> Void,
        onEscape: @escaping () -> Void
    ) {
        clickMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            onOutsideClick()
            return event
        }
        
        clickMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            onOutsideClick()
        }
        
        scrollMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
            guard let screen = NSScreen.main else { return }
            guard UserDefaults.standard.bool(forKey: "clipy_enable_scroll_up_gesture") else { return }
            guard !isPanelDisplayed() else { return }
            
            let mouseLoc = NSEvent.mouseLocation
            if mouseLoc.y <= screen.frame.minY + 60 && (event.deltaY > 0.1 || event.scrollingDeltaY > 0.1) {
                DispatchQueue.main.async {
                    if !isPanelDisplayed() {
                        onBottomScrollUp()
                    }
                }
            }
        }
        
        escapeMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                onEscape()
                return nil
            }
            return event
        }
    }
}
