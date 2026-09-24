//
//  SettingsGeneralSection.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct SettingsGeneralSection: View {
    @Bindable var manager: ClipboardHistoryManager
    @State private var launchAtLoginEnabled = false
    @State private var launchAtLoginNeedsApproval = false
    
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
                
                if launchAtLoginNeedsApproval {
                    HStack {
                        Label("Allow Clipy in Login Items to start it automatically", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Open Settings") {
                            LaunchAtLoginService.openLoginItemsSettings()
                        }
                        .controlSize(.small)
                    }
                    .padding([.horizontal, .bottom])
                }
                
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
        launchAtLoginEnabled = LaunchAtLoginService.isEnabled || LaunchAtLoginService.requiresApproval
        launchAtLoginNeedsApproval = LaunchAtLoginService.requiresApproval
        #endif
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        #if os(macOS)
        LaunchAtLoginService.setEnabled(enabled)
        launchAtLoginNeedsApproval = LaunchAtLoginService.requiresApproval
        #endif
    }
}
