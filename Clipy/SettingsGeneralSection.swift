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
    @State private var pastePermissionGranted = PastePermission.isGranted

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLoginEnabled)
                    .onChange(of: launchAtLoginEnabled) { _, newValue in
                        toggleLaunchAtLogin(enabled: newValue)
                    }
                if launchAtLoginNeedsApproval {
                    LabeledContent {
                        Button("Open Login Items…") {
                            LaunchAtLoginService.openLoginItemsSettings()
                        }
                    } label: {
                        Label("Allow Clipy in Login Items to start automatically", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                LabeledContent("Paste into the previous app") {
                    if pastePermissionGranted {
                        Label("Allowed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant Access…") {
                            PastePermission.request()
                            PastePermission.openAccessibilitySettings()
                        }
                    }
                }
            } footer: {
                Text("Clipy uses Accessibility access to press ⌘V for you. Without it, the item is still copied and you paste it yourself.")
                    .settingsFooter()
            }

            Section {
                Picker("Keep up to", selection: $manager.maxLimit) {
                    Text("25 items").tag(25)
                    Text("50 items").tag(50)
                    Text("100 items").tag(100)
                    Text("200 items").tag(200)
                }
                Picker("Delete items older than", selection: $manager.retentionDays) {
                    Text("Never").tag(0)
                    Text("1 day").tag(1)
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                }
            } header: {
                Text("History")
            } footer: {
                Text("Pinned items and items in a pinboard are always kept.")
                    .settingsFooter()
            }
        }
        .onAppear {
            checkLaunchAtLoginStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            pastePermissionGranted = PastePermission.isGranted
            checkLaunchAtLoginStatus()
        }
    }

    private func checkLaunchAtLoginStatus() {
        launchAtLoginEnabled = LaunchAtLoginService.isEnabled || LaunchAtLoginService.requiresApproval
        launchAtLoginNeedsApproval = LaunchAtLoginService.requiresApproval
    }

    private func toggleLaunchAtLogin(enabled: Bool) {
        LaunchAtLoginService.setEnabled(enabled)
        launchAtLoginNeedsApproval = LaunchAtLoginService.requiresApproval
    }
}

extension Text {
    /// Explanatory text under a settings group, sized and coloured like System Settings.
    func settingsFooter() -> some View {
        self.font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
