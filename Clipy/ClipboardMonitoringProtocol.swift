//
//  ClipboardMonitoringProtocol.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Foundation

/// Protocol defining the interface for monitoring system pasteboard changes.
protocol ClipboardMonitoringProtocol: AnyObject {
    /// Callback triggered whenever new content is copied.
    var onClipboardChanged: ((ClipboardCapture) -> Void)? { get set }

    /// Starts polling and observing pasteboard updates.
    func startMonitoring()

    /// Stops observing pasteboard updates.
    func stopMonitoring()
}
