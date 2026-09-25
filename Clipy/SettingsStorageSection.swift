//
//  SettingsStorageSection.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct SettingsStorageSection: View {
    let manager: ClipboardHistoryManager
    @State private var cacheBytes: Int64 = 0
    @State private var cleanupMessage: String?
    @State private var pendingClear: ClearScope?

    private enum ClearScope: Identifiable {
        case unpinned, all
        var id: Self { self }
    }

    var body: some View {
        Form {
            Section("History") {
                LabeledContent("Items", value: "\(manager.items.count)")
                LabeledContent("Pinned or in a pinboard", value: "\(manager.items.filter(\.isProtected).count)")
            }

            Section {
                LabeledContent("Image cache", value: ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file))
                LabeledContent {
                    Button("Remove Unused Images") { removeUnusedImages() }
                } label: {
                    Text("Unused images")
                    if let cleanupMessage { Text(cleanupMessage) }
                }
            } footer: {
                Text("Images are kept only while they're in your history.")
                    .settingsFooter()
            }

            Section {
                LabeledContent {
                    Button("Clear…", role: .destructive) { pendingClear = .unpinned }
                        .foregroundStyle(.red)
                } label: {
                    Text("Clear history")
                    Text("Keeps pinned and pinboard items.")
                }
                LabeledContent {
                    Button("Clear All…", role: .destructive) { pendingClear = .all }
                        .foregroundStyle(.red)
                } label: {
                    Text("Clear everything")
                    Text("Also removes pinned and pinboard items.")
                }
            }
        }
        .onAppear { refreshCacheSize() }
        .onChange(of: manager.items.count) { refreshCacheSize() }
        .confirmationDialog(
            pendingClear == .all ? "Clear all history, including pinned items?" : "Clear history?",
            isPresented: Binding(get: { pendingClear != nil }, set: { if !$0 { pendingClear = nil } }),
            presenting: pendingClear
        ) { scope in
            Button(scope == .all ? "Clear All" : "Clear History", role: .destructive) {
                manager.clearHistory(includePinned: scope == .all)
            }
        } message: { scope in
            Text(scope == .all
                 ? "Every item, including pinned and pinboard items, will be deleted. This can't be undone."
                 : "Items that aren't pinned or in a pinboard will be deleted. This can't be undone.")
        }
    }

    private func refreshCacheSize() {
        cacheBytes = manager.storage.cacheSizeInBytes()
    }

    private func removeUnusedImages() {
        let referenced = Set(manager.items.compactMap(\.imagePath))
        let freed = manager.storage.removeOrphanedImages(referenced: referenced)
        refreshCacheSize()
        cleanupMessage = freed > 0
            ? "Freed \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))."
            : "Nothing to remove."
    }
}
