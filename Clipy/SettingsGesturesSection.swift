//
//  SettingsGesturesSection.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct SettingsGesturesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gestures & Activation")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Bottom Edge Hover", systemImage: "hand.point.up.left")
                            .foregroundColor(.primary)
                        Text("Triggers on cursor hover (keep off if your Dock is at the bottom).")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "clipy_enable_edge_hover_gesture") },
                        set: { UserDefaults.standard.set($0, forKey: "clipy_enable_edge_hover_gesture") }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                .padding()
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Bottom Edge Swipe / Scroll Up", systemImage: "arrow.up.and.down")
                            .foregroundColor(.primary)
                        Text("Swipe up with two fingers or scroll up at the bottom of the screen.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "clipy_enable_scroll_up_gesture") },
                        set: { UserDefaults.standard.set($0, forKey: "clipy_enable_scroll_up_gesture") }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
