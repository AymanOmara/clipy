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
    let hotkeyManager: HotkeyManaging
    let pasteSimulator: PasteSimulating
    private let menuBarController: MenuBarControlling
    private let settingsController = SettingsWindowController()
    let previewController = PreviewWindowController()
    let animator = PanelPresentationAnimator()
    private let eventMonitorManager = GlobalEventMonitorManager()
    let hotkeySettings = HotkeySettings.shared
    let pasteStack = PasteStack.shared

    // Windows & State
    var panelWindow: ClipboardPanelWindow?
    private var triggerWindow: EdgeTriggerWindow?
    var historyManager: ClipboardHistoryManager?
    var previouslyActiveApp: NSRunningApplication?

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
            self.setupHotkeys()
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

        let actions = PanelActions(
            paste: { [weak self] request in self?.paste(request) },
            preview: { [weak self] entry in self?.togglePreview(entry) },
            openSettings: { [weak self] in self?.openSettings() },
            close: { [weak self] in self?.hidePanel() }
        )
        let contentView = HorizontalContentView(actions: actions)
            .environment(historyManager)
            .environment(pasteStack)

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
            MainActor.assumeIsolated {
                guard let self = self, let trigger = self.triggerWindow, let screen = NSScreen.main else { return }
                let frame = screen.frame
                trigger.setFrame(NSRect(x: frame.minX + (frame.width - 160) / 2, y: frame.minY + 2, width: 160, height: 14), display: true)
                trigger.orderFrontRegardless()
            }
        }
    }

    private func setupMonitors() {
        eventMonitorManager.setup(
            isPanelDisplayed: { [weak self] in self?.isPanelDisplayed ?? false },
            onOutsideClick: { [weak self] in self?.handleOutsideClick() },
            onBottomScrollUp: { [weak self] in self?.showPanel() },
            onEscape: { [weak self] in self?.handleEscape() }
        )
    }

    func togglePanel() {
        if isPanelDisplayed { hidePanel() } else { showPanel() }
    }

    func showPanel() {
        guard let panel = panelWindow, !animator.isAnimating, !isPanelDisplayed else { return }
        previouslyActiveApp = NSWorkspace.shared.frontmostApplication

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelHeight = panel.frame.height
        let panelWidth = panel.frame.width

        panel.setFrame(NSRect(x: screenFrame.minX + (screenFrame.width - panelWidth) / 2, y: screenFrame.minY - panelHeight, width: panelWidth, height: panelHeight), display: true)
        panel.alphaValue = 0.0
        panel.orderFrontRegardless()

        animator.slideUp(panel: panel) { [weak panel] in
            panel?.makeKey()
        }
    }

    func hidePanel() {
        guard let panel = panelWindow, panel.isVisible, !animator.isAnimating else { return }
        previewController.hide()
        animator.slideDown(panel: panel) { [weak self] in
            guard let self = self else { return }
            self.panelWindow?.orderOut(nil)
            if let prevApp = self.previouslyActiveApp {
                prevApp.activate()
                self.previouslyActiveApp = nil
            }
        }
    }

    private func handleEscape() {
        if previewController.isVisible {
            previewController.hide()
        } else {
            hidePanel()
        }
    }

    private func handleOutsideClick() {
        guard let panel = panelWindow, panel.isVisible, NSApp.modalWindow == nil else { return }
        let clickLocation = NSEvent.mouseLocation
        if !NSPointInRect(clickLocation, panel.frame) {
            if settingsController.isPointInsideSettingsWindow(clickLocation) { return }
            if previewController.contains(clickLocation) { return }
            hidePanel()
        }
    }

    private func openSettings() {
        // Settings takes focus, so the panel must not hand it back to the previous app once it slides away.
        previouslyActiveApp = nil
        hidePanel()
        guard let historyManager = self.historyManager else { return }
        settingsController.showSettings(with: historyManager)
    }
}
