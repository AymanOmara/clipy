//
//  HotkeyRecorderView.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI
import AppKit

/// Click-to-record control for a global shortcut. Esc cancels; ⌫ restores the default.
struct HotkeyRecorderView: View {
    let action: HotkeyAction
    @State private var settings = HotkeySettings.shared
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var rejected = false
    @State private var recordingWindow: NSWindow?

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Button(action: toggleRecording) {
                Text(isRecording ? "Type shortcut…" : settings.combo(for: action).displayString)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(isRecording ? Color.accentColor : .primary)
                    .frame(minWidth: 110)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.quaternary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .help("Click, then press the new shortcut")
            .accessibilityLabel("Shortcut \(settings.combo(for: action).displayString). Click to change.")

            if rejected {
                Text("Use ⌘, ⌃ or ⌥ with a key")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if settings.failedActions.contains(action) {
                Text("Shortcut is already in use — kept the previous one")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onDisappear(perform: stopRecording)
        .onChange(of: settings.recordingAction) { _, recording in
            // Another recorder took over.
            if recording != action { stopRecording() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { note in
            // Closing or leaving Preferences ends recording, so keys and shortcuts work again.
            if isRecording, (note.object as? NSWindow) === recordingWindow { stopRecording() }
        }
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }
    
    private func startRecording() {
        let window = NSApp.keyWindow
        isRecording = true
        rejected = false
        recordingWindow = window
        settings.beginRecording(action)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Only capture keys typed into Preferences; the panel and other windows keep theirs.
            guard event.window === window else { return event }
            handle(event)
            return nil
        }
    }
    
    private func handle(_ event: NSEvent) {
        switch Int(event.keyCode) {
        case 53: // Esc
            stopRecording()
        case 51 where event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty: // ⌫
            stopRecording()
            settings.resetToDefault(action)
        default:
            guard let combo = KeyCombo(event: event) else {
                rejected = true
                return
            }
            stopRecording()
            settings.set(combo, for: action)
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recordingWindow = nil
        isRecording = false
        settings.endRecording(action)
    }
}
