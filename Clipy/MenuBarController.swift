//
//  MenuBarController.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa

/// Protocol for controlling the macOS status bar item.
protocol MenuBarControlling: AnyObject {
    func setup(action: @escaping () -> Void)
}

/// Concrete implementation managing an NSStatusItem with click-to-toggle and right-click context menu.
final class MenuBarController: NSObject, MenuBarControlling {
    private var statusItem: NSStatusItem?
    private var clickHandler: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func setup(action: @escaping () -> Void) {
        self.clickHandler = action
        
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "Clipy")
            button.target = self
            button.action = #selector(handleStatusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = item
    }
    
    @objc private func handleStatusItemClicked() {
        guard let event = NSApp.currentEvent else {
            clickHandler?()
            return
        }
        
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showContextMenu()
        } else {
            clickHandler?()
        }
    }
    
    private func showContextMenu() {
        guard let button = statusItem?.button else { return }
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: "Toggle Clipy", action: #selector(menuToggleAction), keyEquivalent: "V")
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let restartItem = NSMenuItem(title: "Restart Clipy", action: #selector(menuRestartAction), keyEquivalent: "r")
        restartItem.target = self
        menu.addItem(restartItem)
        
        let quitItem = NSMenuItem(title: "Quit Clipy", action: #selector(menuQuitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func menuToggleAction() {
        clickHandler?()
    }
    
    @objc private func menuRestartAction() {
        AppLifecycleUtility.restartApp()
    }
    
    @objc private func menuQuitAction() {
        NSApp.terminate(nil)
    }
}
