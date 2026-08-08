//
//  PanelManager.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import Cocoa
import SwiftUI

/// Main coordinator orchestrating floating panel lifecycle, gestures, hotkeys, and window presentations.
final class PanelManager: NSObject {
    static let shared = PanelManager()
    
    // Injected Services
    private let hotkeyManager: HotkeyManaging
    private let pasteSimulator: PasteSimulating
    private let menuBarController: MenuBarControlling
    private let settingsController = SettingsWindowController()
    private let animator = PanelPresentationAnimator()
    private let eventMonitorManager = GlobalEventMonitorManager()
    
    // Windows & State
    private var panelWindow: ClipboardPanelWindow?
    private var triggerWindow: EdgeTriggerWindow?
    private var historyManager: ClipboardHistoryManager?
    private var previouslyActiveApp: NSRunningApplication?
    
    var isPanelDisplayed: Bool {
        guard let panel = panelWindow else { return false }
        return panel.isVisible && panel.alphaValue > 0.1
    }
    
    init(
        hotkeyManager: HotkeyManaging = CarbonHotkeyManager(),
        pasteSimulator: PasteSimulating = CGEventPasteSimulator(),
        menuBarController: MenuBarControlling = MenuBarController()
    ) {
        self.hotkeyManager = hotkeyManager
        self.pasteSimulator = pasteSimulator
        self.menuBarController = menuBarController
        super.init()
    }
    
    func setup(historyManager: ClipboardHistoryManager) {
        self.historyManager = historyManager
        
        UserDefaults.standard.register(defaults: [
            "clipy_enable_edge_hover_gesture": false,
            "clipy_enable_scroll_up_gesture": true
        ])
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.menuBarController.setup { [weak self] in self?.togglePanel() }
            self.createPanelWindow()
            self.createEdgeTriggerWindow()
            self.setupMonitors()
            self.setupScreenChangeObserver()
            self.hotkeyManager.register { [weak self] in self?.togglePanel() }
        }
    }
    
    private func createPanelWindow() {
        guard let historyManager = self.historyManager else { return }
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelHeight: CGFloat = 260
        let panelWidth = min(1200, screenFrame.width - 80)
        
        let initialFrame = NSRect(
            x: screenFrame.minX + (screenFrame.width - panelWidth) / 2,
            y: screenFrame.minY - panelHeight - 100,
            width: panelWidth,
            height: panelHeight
        )
        
        let panel = ClipboardPanelWindow(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        let contentView = HorizontalContentView(
            onCopyAndPaste: { [weak self] item in self?.copyAndPasteItem(item) },
            onOpenSettings: { [weak self] in self?.openSettings() },
            onClose: { [weak self] in self?.hidePanel() }
        )
        .environment(historyManager)
        
        panel.contentView = NSHostingView(rootView: contentView)
        self.panelWindow = panel
    }
    
    private func createEdgeTriggerWindow() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let pillWidth: CGFloat = 160
        let pillHeight: CGFloat = 14
        
        let trigger = EdgeTriggerWindow(
            contentRect: NSRect(
                x: screenFrame.minX + (screenFrame.width - pillWidth) / 2,
                y: screenFrame.minY + 2,
                width: pillWidth,
                height: pillHeight
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        let pillView = PillHandleView(onClick: { [weak self] in self?.togglePanel() })
        let hostingView = NSHostingView(rootView: pillView)
        hostingView.autoresizingMask = [.width, .height]
        trigger.contentView = hostingView
        trigger.onScrollUp = { [weak self] in
            guard let self = self, !self.isPanelDisplayed else { return }
            self.showPanel()
        }
        
        self.triggerWindow = trigger
        trigger.orderFrontRegardless()
    }
    
    private func setupScreenChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let trigger = self.triggerWindow, let screen = NSScreen.main else { return }
            let frame = screen.frame
            trigger.setFrame(NSRect(
                x: frame.minX + (frame.width - 160) / 2,
                y: frame.minY + 2,
                width: 160,
                height: 14
            ), display: true)
            trigger.orderFrontRegardless()
        }
    }
    
    private func setupMonitors() {
        eventMonitorManager.setup(
            isPanelDisplayed: { [weak self] in self?.isPanelDisplayed ?? false },
            onOutsideClick: { [weak self] in self?.handleOutsideClick() },
            onBottomScrollUp: { [weak self] in self?.showPanel() },
            onEscape: { [weak self] in self?.hidePanel() }
        )
    }
    
    func togglePanel() {
        if isPanelDisplayed {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    func showPanel() {
        guard let panel = panelWindow, !animator.isAnimating, !isPanelDisplayed else { return }
        previouslyActiveApp = NSWorkspace.shared.frontmostApplication
        
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelHeight = panel.frame.height
        let panelWidth = panel.frame.width
        
        panel.setFrame(NSRect(
            x: screenFrame.minX + (screenFrame.width - panelWidth) / 2,
            y: screenFrame.minY - panelHeight,
            width: panelWidth,
            height: panelHeight
        ), display: true)
        panel.alphaValue = 0.0
        panel.orderFrontRegardless()
        
        animator.slideUp(panel: panel) { [weak panel] in
            panel?.makeKey()
        }
    }
    
    func hidePanel() {
        guard let panel = panelWindow, panel.isVisible, !animator.isAnimating else { return }
        
        animator.slideDown(panel: panel) { [weak self] in
            guard let self = self else { return }
            self.panelWindow?.orderOut(nil)
            if let prevApp = self.previouslyActiveApp {
                prevApp.activate()
                self.previouslyActiveApp = nil
            }
        }
    }
    
    private func handleOutsideClick() {
        guard let panel = panelWindow, panel.isVisible else { return }
        let clickLocation = NSEvent.mouseLocation
        if !NSPointInRect(clickLocation, panel.frame) {
            if settingsController.isPointInsideSettingsWindow(clickLocation) { return }
            hidePanel()
        }
    }
    
    private func copyAndPasteItem(_ item: ClipboardHistoryItem) {
        guard let historyManager = historyManager, let panel = panelWindow else { return }
        historyManager.copyToClipboard(item)
        let targetApp = previouslyActiveApp
        
        animator.slideDown(panel: panel) { [weak self] in
            guard let self = self else { return }
            self.panelWindow?.orderOut(nil)
            if let app = targetApp {
                app.activate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.pasteSimulator.simulatePaste()
                }
            } else {
                self.pasteSimulator.simulatePaste()
            }
        }
    }
    
    private func openSettings() {
        hidePanel()
        guard let historyManager = self.historyManager else { return }
        settingsController.showSettings(with: historyManager)
    }
}
