//
//  SettingsPinboardsSection.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// Manage named pinboards; items are filed into them from a card's right-click menu.
struct SettingsPinboardsSection: View {
    let manager: ClipboardHistoryManager
    @State private var pendingDeletion: Pinboard?

    var body: some View {
        Form {
            Section {
                if manager.pinboards.isEmpty {
                    Text("No pinboards yet. Use them to group items like Work, Code or Replies.")
                        .foregroundStyle(.secondary)
                }
                ForEach(manager.pinboards) { board in
                    LabeledContent {
                        HStack(spacing: 12) {
                            Button("Rename…") { rename(board) }
                            Button("Delete", role: .destructive) { pendingDeletion = board }
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    } label: {
                        Label {
                            Text(board.name)
                            Text(itemCount(board))
                        } icon: {
                            Circle().fill(board.color).frame(width: 12, height: 12)
                        }
                    }
                }
                Button("New Pinboard…") {
                    if let name = TextPrompt.run(title: "New Pinboard", confirmTitle: "Create") {
                        manager.createPinboard(named: name)
                    }
                }
                .buttonStyle(.borderless)
            } footer: {
                Text("Add an item to a pinboard by right-clicking it in the clipboard panel. Items in a pinboard are never deleted automatically.")
                    .settingsFooter()
            }
        }
        .confirmationDialog(
            "Delete the “\(pendingDeletion?.name ?? "")” pinboard?",
            isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
            presenting: pendingDeletion
        ) { board in
            Button("Delete Pinboard", role: .destructive) { manager.deletePinboard(board) }
        } message: { _ in
            Text("Its items stay in your history.")
        }
    }

    private func itemCount(_ board: Pinboard) -> String {
        let count = manager.items.filter { $0.pinboardID == board.id }.count
        return count == 1 ? "1 item" : "\(count) items"
    }

    private func rename(_ board: Pinboard) {
        if let name = TextPrompt.run(title: "Rename Pinboard", defaultValue: board.name) {
            manager.renamePinboard(board, to: name)
        }
    }
}
