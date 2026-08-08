//
//  PasteSimulator.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation
import CoreGraphics

/// Protocol defining the capability to synthesize a paste keystroke into the active app.
protocol PasteSimulating: AnyObject {
    /// Simulates Cmd+V keystroke via system event tap.
    func simulatePaste()
}

/// CoreGraphics implementation of `PasteSimulating` using virtual key events.
final class CGEventPasteSimulator: PasteSimulating {
    private let virtualKeyV: CGKeyCode = 0x09 // Virtual key code for 'v'
    
    func simulatePaste() {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        
        let cmdVKeyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: virtualKeyV, keyDown: true)
        cmdVKeyDown?.flags = CGEventFlags.maskCommand
        
        let cmdVKeyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: virtualKeyV, keyDown: false)
        cmdVKeyUp?.flags = CGEventFlags.maskCommand
        
        cmdVKeyDown?.post(tap: .cgSessionEventTap)
        cmdVKeyUp?.post(tap: .cgSessionEventTap)
    }
}
