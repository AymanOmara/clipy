//
//  MenuBarController.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa

/// Protocol for controlling the macOS status bar item.
protocol MenuBarControlling: AnyObject {
    /// Configures the status item button with an action target.
    func setup(action: @escaping () -> Void)
}

/// Concrete implementation managing an NSStatusItem in the system menu bar.
final class MenuBarController: MenuBarControlling {
    private var statusItem: NSStatusItem?
    private var clickHandler: (() -> Void)?
    
    init() {}
    
    func setup(action: @escaping () -> Void) {
        self.clickHandler = action
        
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "Clipy")
            button.target = self
            button.action = #selector(handleStatusItemClicked)
        }
        self.statusItem = item
    }
    
    @objc private func handleStatusItemClicked() {
        clickHandler?()
    }
}
