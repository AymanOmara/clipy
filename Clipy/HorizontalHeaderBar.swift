//
//  HorizontalHeaderBar.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct HorizontalHeaderBar: View {
    @Environment(ClipboardHistoryManager.self) var manager
    @Environment(PasteStack.self) var pasteStack

    @Binding var searchText: String
    @Binding var selectedFilter: FilterType
    var onResetSelection: () -> Void
    var onOpenSettings: () -> Void
    var onClose: () -> Void

    @State private var isCloseHovered = false

    var body: some View {
        HStack(spacing: 16) {
            brandTitle
            searchField
            filterPills
            if !pasteStack.isEmpty {
                PasteStackStatus()
            }
            HStack(spacing: 8) {
                preferencesButton
                closeButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var brandTitle: some View {
        HStack(spacing: 8) {
            Image(systemName: "paperclip")
                .font(.title3)
                .foregroundColor(.accentColor)
            Text("Clipy")
                .font(.headline)
                .fontWeight(.bold)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search, or app: type: date:…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .help(SearchQuery.helpText)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onResetSelection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .frame(maxWidth: 280)
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FilterType.builtIn) { filter in
                    FilterPill(title: filter.title, icon: filter.icon, tint: nil, isSelected: selectedFilter == filter) {
                        select(filter)
                    }
                }

                if !manager.pinboards.isEmpty {
                    Divider().frame(height: 16)
                }

                ForEach(manager.pinboards) { board in
                    FilterPill(title: board.name, icon: "circle.fill", tint: board.color, isSelected: selectedFilter == .pinboard(board.id)) {
                        select(.pinboard(board.id))
                    }
                    .contextMenu {
                        Button("Rename…") {
                            if let name = TextPrompt.run(title: "Rename Pinboard", defaultValue: board.name) {
                                manager.renamePinboard(board, to: name)
                            }
                        }
                        Button("Delete Pinboard", role: .destructive) { manager.deletePinboard(board) }
                    }
                }

                Button {
                    if let name = TextPrompt.run(title: "New Pinboard", message: "Right-click any card to add it to this pinboard.", confirmTitle: "Create") {
                        select(.pinboard(manager.createPinboard(named: name).id))
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .padding(6)
                        .background(Circle().fill(Color.primary.opacity(0.04)))
                }
                .buttonStyle(.plain)
                .help("New Pinboard")
            }
        }
    }

    private func select(_ filter: FilterType) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            selectedFilter = filter
            onResetSelection()
        }
    }

    private var preferencesButton: some View {
        Button(action: onOpenSettings) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.primary.opacity(0.04))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Open Settings")
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isCloseHovered ? .white : .red)
                .padding(8)
                .background(isCloseHovered ? Color.red.opacity(0.9) : Color.red.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isCloseHovered = hovering
            }
        }
        .help("Close Panel (Esc)")
    }
}
