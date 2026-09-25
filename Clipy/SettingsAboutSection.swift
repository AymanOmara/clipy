//
//  SettingsAboutSection.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

struct SettingsAboutSection: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 72, height: 72)
                    Text("Clipy")
                        .font(.title2.weight(.semibold))
                    Text(version)
                        .foregroundStyle(.secondary)
                    Text("A private clipboard manager for your Mac.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section {
                LabeledContent {
                    Button("Restart") { AppLifecycleUtility.restartApp() }
                } label: {
                    Text("Restart Clipy")
                    Text("Useful after granting a permission.")
                }
                LabeledContent {
                    Button("Quit") { NSApp.terminate(nil) }
                } label: {
                    Text("Quit Clipy")
                    Text("History is saved and restored next time.")
                }
            }
        }
    }
}
