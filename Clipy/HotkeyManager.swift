//
//  HotkeyManager.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation
import Carbon

/// Protocol for registering and handling system-wide hotkeys.
protocol HotkeyManaging: AnyObject {
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void)
    func unregister()
}

extension HotkeyManaging {
    /// Registers default global hotkey (⌘ + Shift + V)
    func register(handler: @escaping () -> Void) {
        register(keyCode: 0x09, modifiers: UInt32(cmdKey | shiftKey), handler: handler)
    }
}

/// Carbon-based implementation of `HotkeyManaging` using `RegisterEventHotKey`.
final class CarbonHotkeyManager: HotkeyManaging {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var actionHandler: (() -> Void)?
    
    private let hotKeySignature: OSType = 0x434C5059 // 'CLPY'
    private let hotKeyId: UInt32 = 1
    
    init() {}
    
    deinit {
        unregister()
    }
    
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        unregister()
        self.actionHandler = handler
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<CarbonHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.actionHandler?()
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
            return
        }
        
        var hotKeyID = EventHotKeyID(signature: hotKeySignature, id: hotKeyId)
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if regStatus != noErr {
            print("[CarbonHotkeyManager] Failed to register global hotkey: \(regStatus)")
        }
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        actionHandler = nil
    }
}
