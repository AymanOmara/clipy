//
//  SettingsPrivacySection.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// Apps whose copies Clipy never records.
struct SettingsPrivacySection: View {
    @State private var store = ExcludedAppsStore.shared

    var body: some View {
        Form {
            Section {
                ForEach(store.apps) { app in
                    LabeledContent {
                        Button("Remove") { store.remove(app) }
                            .buttonStyle(.borderless)
                    } label: {
                        Label {
                            Text(app.name)
                            Text(app.bundleID)
                        } icon: {
                            appIcon(for: app)
                        }
                    }
                }
                Button("Add App…") { store.addFromOpenPanel() }
                    .buttonStyle(.borderless)
            } header: {
                Text("Ignored Apps")
            } footer: {
                Text("Nothing you copy while one of these apps is in front is saved to history.")
                    .settingsFooter()
            }

            Section {
                LabeledContent("Passwords and other concealed data") {
                    Label("Never saved", systemImage: "lock.fill")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Network access") {
                    Label("None", systemImage: "wifi.slash")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("History stays on this Mac. Password managers that mark copied data as concealed are always skipped.")
                    .settingsFooter()
            }
        }
    }

    @ViewBuilder
    private func appIcon(for app: ExcludedApp) -> some View {
        if let icon = AppIconCache.icon(for: app.bundleID) {
            Image(nsImage: icon).resizable().frame(width: 24, height: 24)
        } else {
            Image(systemName: "app.dashed")
                .font(.title3)
                .foregroundStyle(.tertiary)
                .frame(width: 24, height: 24)
        }
    }
}
