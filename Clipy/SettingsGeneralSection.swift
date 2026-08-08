//
//  SettingsGeneralSection.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI
#if os(macOS)
import ServiceManagement
#endif

struct SettingsGeneralSection: View {
    @Bindable var manager: ClipboardHistoryManager
    @State private var launchAtLoginEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                #if os(macOS)
                HStack {
                    Label("Launch at Login", systemImage: "macwindow.and.key")
                        .foregroundColor(.primary)
                    Spacer()
                    Toggle("", isOn: $launchAtLoginEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: launchAtLoginEnabled) { _, newValue in
                            toggleLaunchAtLogin(enabled: newValue)
                        }
                }
                .padding()
                
                Divider()
                #endif
                
                HStack {
                    Label("History Limit", systemImage: "clock.arrow.circlepath")
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: $manager.maxLimit) {
                        Text("25 items").tag(25)
                        Text("50 items").tag(50)
                        Text("100 items").tag(100)
                        Text("200 items").tag(200)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 110)
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
        .onAppear {
            checkLaunchAtLoginStatus()
        }
    }
    
    private func checkLaunchAtLoginStatus() {
        #if os(macOS)
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        #endif
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        #if os(macOS)
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("[SettingsGeneralSection] Failed to update launch at login: \(error)")
        }
        #endif
    }
}
