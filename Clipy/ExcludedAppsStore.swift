//
//  ExcludedAppsStore.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import AppKit
import Observation
import UniformTypeIdentifiers

struct ExcludedApp: Codable, Hashable, Identifiable {
    let bundleID: String
    let name: String
    var id: String { bundleID }
}

/// Apps whose copies are never recorded, whether or not they mark their data as concealed.
@Observable
final class ExcludedAppsStore {
    static let shared = ExcludedAppsStore()

    private static let defaultsKey = "clipy_excluded_apps"

    static let defaultApps: [ExcludedApp] = [
        ExcludedApp(bundleID: "com.apple.keychainaccess", name: "Keychain Access"),
        ExcludedApp(bundleID: "com.apple.Passwords", name: "Passwords"),
        ExcludedApp(bundleID: "com.1password.1password", name: "1Password"),
        ExcludedApp(bundleID: "com.agilebits.onepassword7", name: "1Password 7"),
        ExcludedApp(bundleID: "com.bitwarden.desktop", name: "Bitwarden"),
        ExcludedApp(bundleID: "com.lastpass.LastPass", name: "LastPass")
    ]

    private(set) var apps: [ExcludedApp] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([ExcludedApp].self, from: data) {
            apps = saved
        } else {
            apps = Self.defaultApps
        }
    }

    func isExcluded(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return apps.contains { $0.bundleID == bundleID }
    }

    func add(_ app: ExcludedApp) {
        guard !apps.contains(where: { $0.bundleID == app.bundleID }) else { return }
        apps.append(app)
        save()
    }

    func remove(_ app: ExcludedApp) {
        apps.removeAll { $0.bundleID == app.bundleID }
        save()
    }

    /// Lets the user pick an application bundle and adds it to the list.
    func addFromOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = "Choose an App to Exclude"
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier else { continue }
            let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
            add(ExcludedApp(bundleID: bundleID, name: name))
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
