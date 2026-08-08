//
//  ClipboardMonitor.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import Foundation
import AppKit

/// Observes system pasteboard updates and notifies listeners when new items are copied.
final class ClipboardMonitor: ClipboardMonitoringProtocol {
    private let pasteboard: NSPasteboard
    private var lastChangeCount: Int
    private var timer: Timer?
    
    var onClipboardChanged: ((ClipboardHistoryItem) -> Void)?
    
    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        stopMonitoring()
        
        // Poll the pasteboard changeCount periodically
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkPasteboard() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
        
        // 1. Check for File URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = urls.first,
           firstURL.isFileURL {
            let item = ClipboardHistoryItem(
                type: .file,
                fileName: firstURL.lastPathComponent,
                fileURL: firstURL,
                sourceAppName: sourceApp
            )
            onClipboardChanged?(item)
            return
        }
        
        // 2. Check for Images
        if pasteboard.canReadObject(forClasses: [NSImage.self], options: nil),
           let tiffData = pasteboard.data(forType: .tiff),
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("\(UUID().uuidString).png")
            
            do {
                try pngData.write(to: tempFile)
                let item = ClipboardHistoryItem(
                    type: .image,
                    fileURL: tempFile,
                    sourceAppName: sourceApp
                )
                onClipboardChanged?(item)
                return
            } catch {
                print("[ClipboardMonitor] Failed to write temporary image: \(error)")
            }
        }
        
        // 3. Check for Plain/Rich Text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            let item = ClipboardHistoryItem(
                type: .text,
                stringValue: text,
                sourceAppName: sourceApp
            )
            onClipboardChanged?(item)
            return
        }
    }
}
