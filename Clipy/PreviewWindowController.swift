//
//  PreviewWindowController.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Cocoa
import SwiftUI

/// Floating Quick Look–style window above the clipboard panel. It never takes key focus,
/// so the panel keeps receiving Space / arrows / Esc while the preview is open.
final class PreviewWindowController {
    private var window: NSPanel?
    private(set) var entryID: UUID?

    var isVisible: Bool { window?.isVisible ?? false }

    func contains(_ point: NSPoint) -> Bool {
        guard let window, window.isVisible else { return false }
        return NSPointInRect(point, window.frame)
    }

    /// Shows `entry`, or hides the preview if it is already showing that entry.
    func toggle(_ entry: PanelEntry, above anchor: NSRect, manager: ClipboardHistoryManager) {
        if isVisible && entryID == entry.id {
            hide()
            return
        }
        show(entry, above: anchor, manager: manager)
    }

    func show(_ entry: PanelEntry, above anchor: NSRect, manager: ClipboardHistoryManager) {
        let panel = window ?? makeWindow()
        let size = NSSize(width: min(720, anchor.width - 40), height: 440)
        let origin = NSPoint(x: anchor.midX - size.width / 2, y: anchor.maxY + 12)
        panel.setFrame(NSRect(origin: origin, size: size), display: false)

        let view = PreviewView(entry: entry, onClose: { [weak self] in self?.hide() })
            .environment(manager)
        panel.contentView = NSHostingView(rootView: view)
        panel.orderFrontRegardless()
        window = panel
        entryID = entry.id
    }

    func hide() {
        window?.orderOut(nil)
        entryID = nil
    }

    private func makeWindow() -> NSPanel {
        let panel = PreviewPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar + 1
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }
}

private final class PreviewPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
