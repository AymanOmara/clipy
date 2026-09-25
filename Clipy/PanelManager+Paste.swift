//
//  PanelManager+Paste.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Cocoa

extension PanelManager {
    /// Registers the user's shortcuts and lets Preferences re-apply or suspend them.
    func setupHotkeys() {
        hotkeySettings.applyHandler = { [weak self] action, combo in
            guard let self else { return false }
            return self.hotkeyManager.register(combo, for: action) { [weak self] in
                switch action {
                case .togglePanel: self?.togglePanel()
                case .pasteNextInStack: self?.pasteNextFromStack()
                }
            }
        }
        hotkeySettings.suspendHandler = { [weak self] suspended in
            guard let self else { return }
            if suspended {
                HotkeyAction.allCases.forEach(self.hotkeyManager.unregister)
            } else {
                HotkeyAction.allCases.forEach(self.hotkeySettings.apply)
            }
        }
        HotkeyAction.allCases.forEach(hotkeySettings.apply)
    }

    /// Puts the requested content on the pasteboard, closes the panel and pastes into the previous app.
    func paste(_ request: PasteRequest) {
        guard let historyManager = historyManager, let panel = panelWindow else { return }
        switch request {
        case let .item(item, plainText):
            guard historyManager.copyToClipboard(item, plainTextOnly: plainText) else {
                NSSound.beep()
                return
            }
        case let .text(text):
            historyManager.copyText(text)
        }
        previewController.hide()
        let targetApp = previouslyActiveApp
        let canPaste = PastePermission.isGranted

        animator.slideDown(panel: panel) { [weak self] in
            guard let self = self else { return }
            self.panelWindow?.orderOut(nil)
            guard canPaste else {
                // Item stays on the clipboard for a manual ⌘V; point the user at the missing permission.
                targetApp?.activate()
                PastePermission.request()
                PastePermission.openAccessibilitySettings()
                return
            }
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

    /// Handler for the "Paste Next" shortcut: pastes the next paste-stack entry into the frontmost app.
    func pasteNextFromStack() {
        guard let historyManager,
              let item = pasteStack.popNext(from: historyManager.items),
              historyManager.copyToClipboard(item) else {
            NSSound.beep()
            return
        }
        guard PastePermission.isGranted else {
            PastePermission.promptIfNeeded()
            return
        }
        // Let the user release the shortcut's modifiers so they don't combine with the synthetic ⌘V.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.pasteSimulator.simulatePaste()
        }
    }

    func togglePreview(_ entry: PanelEntry) {
        guard let historyManager, let panel = panelWindow else { return }
        previewController.toggle(entry, above: panel.frame, manager: historyManager)
    }
}
