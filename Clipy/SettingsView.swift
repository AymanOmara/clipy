//
//  SettingsView.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import SwiftUI

/// Settings window laid out like macOS System Settings: a sidebar of panes and a grouped form.
struct SettingsView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    @AppStorage("clipy_settings_pane") private var selection: SettingsPane = .general

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(get: { selection }, set: { if let pane = $0 { selection = pane } })) {
                ForEach(SettingsPane.allCases) { pane in
                    Label {
                        Text(pane.title)
                    } icon: {
                        SettingsPaneIcon(pane: pane)
                    }
                    .tag(pane)
                    .padding(.vertical, 1)

                    if pane.endsGroup {
                        Spacer().frame(height: 6)
                            .listRowSeparator(.hidden)
                            .selectionDisabled()
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 200, max: 240)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            pane(selection)
                .formStyle(.grouped)
                .navigationTitle(selection.title)
                .frame(minWidth: 460)
        }
        .frame(minWidth: 680, minHeight: 480)
    }

    @ViewBuilder
    private func pane(_ pane: SettingsPane) -> some View {
        switch pane {
        case .general: SettingsGeneralSection(manager: manager)
        case .shortcuts: SettingsShortcutsSection()
        case .gestures: SettingsGesturesSection()
        case .privacy: SettingsPrivacySection()
        case .snippets: SettingsSnippetsSection(manager: manager)
        case .pinboards: SettingsPinboardsSection(manager: manager)
        case .storage: SettingsStorageSection(manager: manager)
        case .about: SettingsAboutSection()
        }
    }
}
