//
//  HotkeyManager.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation
import Carbon

/// Global shortcuts Clipy registers with the system.
enum HotkeyAction: UInt32, CaseIterable {
    case togglePanel = 1
    case pasteNextInStack = 2
}

/// Protocol for registering and handling system-wide hotkeys.
protocol HotkeyManaging: AnyObject {
    /// Registers `combo` for `action`, replacing any previous combo; false if the system refused it
    /// (in which case the previous combo stays registered).
    @discardableResult
    func register(_ combo: KeyCombo, for action: HotkeyAction, handler: @escaping () -> Void) -> Bool
    func unregister(_ action: HotkeyAction)
    func unregisterAll()
}

/// Carbon-based implementation of `HotkeyManaging` using `RegisterEventHotKey`.
final class CarbonHotkeyManager: HotkeyManaging {
    private var hotKeyRefs: [HotkeyAction: EventHotKeyRef] = [:]
    private var handlers: [HotkeyAction: () -> Void] = [:]
    private var registeredCombos: [HotkeyAction: KeyCombo] = [:]
    private var eventHandler: EventHandlerRef?
    
    private let hotKeySignature: OSType = 0x434C5059 // 'CLPY'
    
    init() {}
    
    deinit {
        MainActor.assumeIsolated { unregisterAll() }
    }
    
    @discardableResult
    func register(_ combo: KeyCombo, for action: HotkeyAction, handler: @escaping () -> Void) -> Bool {
        installEventHandlerIfNeeded()
        if registeredCombos[action] == combo, hotKeyRefs[action] != nil {
            handlers[action] = handler
            return true
        }
        
        // Register the new combo before dropping the old one, so a refused shortcut keeps the working one.
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: action.rawValue)
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        guard status == noErr, let ref = hotKeyRef else {
            print("[CarbonHotkeyManager] Failed to register \(combo.displayString): \(status)")
            return false
        }
        unregister(action)
        hotKeyRefs[action] = ref
        registeredCombos[action] = combo
        handlers[action] = handler
        return true
    }
    
    func unregister(_ action: HotkeyAction) {
        if let ref = hotKeyRefs.removeValue(forKey: action) {
            UnregisterEventHotKey(ref)
        }
        registeredCombos[action] = nil
        handlers[action] = nil
    }

    func unregisterAll() {
        HotkeyAction.allCases.forEach(unregister)
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    fileprivate func handle(_ id: UInt32) {
        guard let action = HotkeyAction(rawValue: id) else { return }
        handlers[action]?()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let event, let userData else { return noErr }
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID
                )
                guard result == noErr else { return result }
                let manager = Unmanaged<CarbonHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                let id = hotKeyID.id
                DispatchQueue.main.async {
                    manager.handle(id)
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )

        if status != noErr {
            print("[CarbonHotkeyManager] Failed to install event handler: \(status)")
        }
    }
}
