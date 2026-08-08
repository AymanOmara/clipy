//
//  SettingsView.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    @Binding var isPresented: Bool
    
    var body: some View {
        @Bindable var manager = manager
        VStack(spacing: 0) {
            headerBar
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    SettingsGeneralSection(manager: manager)
                    SettingsGesturesSection()
                    SettingsStorageSection(manager: manager)
                    footerBranding
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
    }
    
    private var headerBar: some View {
        HStack {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.primary.opacity(0.03))
    }
    
    private var footerBranding: some View {
        VStack(spacing: 4) {
            Text("Clipy Clipboard Manager")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Version 1.0.0 (Build 1)")
                .font(.caption2)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .padding(.top, 10)
    }
}
