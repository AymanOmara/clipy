//
//  ClipboardCapture.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import Foundation

/// Raw content read from the pasteboard, before it is deduplicated and turned into a history item.
nonisolated struct ClipboardCapture: Sendable {
    enum Content: Sendable {
        case text(String, rtf: Data?, html: String?)
        case files([URL])
        /// TIFF bytes as provided by the pasteboard; encoding to PNG happens off the main thread.
        case image(Data)
    }

    let content: Content
    let sourceAppName: String?
    let sourceBundleID: String?
    /// Pasteboard change count this content was read at; lets Clipy recognise its own writes.
    let changeCount: Int
}
