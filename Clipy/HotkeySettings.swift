//
//  HotkeySettings.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation
import Observation

/// User-chosen global shortcuts, persisted in UserDefaults and applied by `PanelManager`.
@Observable
final class HotkeySettings {
    static let shared = HotkeySettings()

    private(set) var toggleCombo: KeyCombo
    private(set) var pasteNextCombo: KeyCombo
    /// Actions whose last registration the system refused (shortcut already taken).
    private(set) var failedActions: Set<HotkeyAction> = []

    /// Installed by `PanelManager`: registers the given combo and reports success.
    @ObservationIgnored var applyHandler: ((HotkeyAction, KeyCombo) -> Bool)?
    /// Installed by `PanelManager`: pauses or resumes all shortcuts while one is being recorded.
    @ObservationIgnored var suspendHandler: ((Bool) -> Void)?

    private init() {
        toggleCombo = Self.load(.togglePanel) ?? .defaultToggle
        pasteNextCombo = Self.load(.pasteNextInStack) ?? .defaultPasteNext
    }

    func combo(for action: HotkeyAction) -> KeyCombo {
        action == .togglePanel ? toggleCombo : pasteNextCombo
    }

    /// Registers and saves `combo`; if the system (or the other Clipy shortcut) already uses it,
    /// the previous shortcut stays active and nothing is saved.
    @discardableResult
    func set(_ combo: KeyCombo, for action: HotkeyAction) -> Bool {
        let other = HotkeyAction.allCases.first { $0 != action }
        let clashesWithOther = other.map { self.combo(for: $0) == combo } ?? false
        guard !clashesWithOther, applyHandler?(action, combo) ?? true else {
            failedActions.insert(action)
            return false
        }
        failedActions.remove(action)
        switch action {
        case .togglePanel: toggleCombo = combo
        case .pasteNextInStack: pasteNextCombo = combo
        }
        if let data = try? JSONEncoder().encode(combo) {
            UserDefaults.standard.set(data, forKey: Self.key(action))
        }
        return true
    }
    
    func resetToDefault(_ action: HotkeyAction) {
        set(action == .togglePanel ? .defaultToggle : .defaultPasteNext, for: action)
    }
    
    func apply(_ action: HotkeyAction) {
        guard let applyHandler else { return }
        if applyHandler(action, combo(for: action)) {
            failedActions.remove(action)
        } else {
            failedActions.insert(action)
        }
    }
    
    /// The shortcut currently being recorded in Preferences; only one recorder is active at a time.
    private(set) var recordingAction: HotkeyAction?
    
    func beginRecording(_ action: HotkeyAction) {
        if recordingAction == nil { suspendHandler?(true) }
        recordingAction = action
    }
    
    func endRecording(_ action: HotkeyAction) {
        guard recordingAction == action else { return }
        recordingAction = nil
        suspendHandler?(false)
    }

    private static func key(_ action: HotkeyAction) -> String {
        "clipy_hotkey_\(action.rawValue)"
    }

    private static func load(_ action: HotkeyAction) -> KeyCombo? {
        guard let data = UserDefaults.standard.data(forKey: key(action)) else { return nil }
        return try? JSONDecoder().decode(KeyCombo.self, from: data)
    }
}
