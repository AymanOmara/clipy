//
//  LaunchAtLoginService.swift
//  Clipy
//
//  Created by Ayman Omara on 24/09/2026.
//

import Foundation
import ServiceManagement

/// Registers Clipy as a login item so it relaunches after a restart, shutdown or logout.
enum LaunchAtLoginService {
    private static let didConfigureKey = "clipy_did_configure_launch_at_login"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// True when registered but the user still has to allow it in System Settings › Login Items.
    static var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// Enables launch at login on the very first run; later runs respect the user's choice.
    static func enableOnFirstLaunch() {
        guard !UserDefaults.standard.bool(forKey: didConfigureKey) else { return }
        UserDefaults.standard.set(true, forKey: didConfigureKey)
        setEnabled(true)
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[LaunchAtLoginService] Failed to update launch at login: \(error)")
        }
    }

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
