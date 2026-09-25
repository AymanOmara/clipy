//
//  SettingsGesturesSection.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct SettingsGesturesSection: View {
    @AppStorage("clipy_enable_scroll_up_gesture") private var scrollUpEnabled = true
    @AppStorage("clipy_enable_edge_hover_gesture") private var edgeHoverEnabled = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $scrollUpEnabled) {
                    Text("Swipe up from the bottom edge")
                    Text("Swipe up with two fingers, or scroll up, at the bottom of the screen.")
                }
                Toggle(isOn: $edgeHoverEnabled) {
                    Text("Open when the pointer rests on the bottom edge")
                    Text("Leave this off if your Dock is at the bottom of the screen.")
                }
            } footer: {
                Text("You can always open Clipy with its shortcut, the menu bar icon, or the pill at the bottom of the screen.")
                    .settingsFooter()
            }
        }
    }
}
