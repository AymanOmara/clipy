//
//  HorizontalContentView.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import SwiftUI
import AppKit

/// Callbacks from the panel UI into `PanelManager`.
struct PanelActions {
    var paste: (PasteRequest) -> Void
    var preview: (PanelEntry) -> Void
    var openSettings: () -> Void
    var close: () -> Void
}

/// Primary horizontal card container view displaying clipboard history, search, and category filters.
struct HorizontalContentView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    @Environment(PasteStack.self) var pasteStack

    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var hoveredItemId: UUID? = nil
    @State private var selectedIndex: Int = 0
    @FocusState private var isListFocused: Bool

    let actions: PanelActions

    var body: some View {
        VStack(spacing: 0) {
            HorizontalHeaderBar(
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                onResetSelection: { selectedIndex = 0 },
                onOpenSettings: actions.openSettings,
                onClose: actions.close
            )

            Divider().opacity(0.5)

            cardsContainer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .onChange(of: searchText) {
            selectedIndex = 0
        }
        .onChange(of: manager.pinboards) {
            if case let .pinboard(id) = selectedFilter, !manager.pinboards.contains(where: { $0.id == id }) {
                selectedFilter = .all
            }
        }
    }

    @ViewBuilder
    private var cardsContainer: some View {
        let entries = filteredEntries()

        if entries.isEmpty {
            EmptyClipboardView(searchText: searchText, isSnippets: selectedFilter == .snippets)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            card(for: entry, index: index, count: entries.count)
                                .id(index)
                                .onTapGesture {
                                    selectedIndex = index
                                    paste(entry, plainText: NSEvent.modifierFlags.contains(.option))
                                }
                                .onHover { hovering in
                                    hoveredItemId = hovering ? entry.id : nil
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: selectedIndex) { _, newIndex in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .focused($isListFocused)
            .focusable()
            .focusEffectDisabled()
            .modifier(PanelKeyboardHandler(
                entries: entries,
                selectedIndex: $selectedIndex,
                paste: paste,
                preview: actions.preview,
                toggleStack: { if case let .item(item) = $0 { pasteStack.toggle(item) } }
            ))
            .onAppear {
                isListFocused = true
            }
        }
    }

    @ViewBuilder
    private func card(for entry: PanelEntry, index: Int, count: Int) -> some View {
        let isSelected = index == selectedIndex && isListFocused
        switch entry {
        case let .item(item):
            ClipboardCardView(
                item: item,
                indexHint: index < 9 ? index + 1 : nil,
                isSelected: isSelected,
                isHovered: hoveredItemId == item.id,
                actions: actions,
                onDelete: {
                    manager.deleteItem(item)
                    if selectedIndex >= max(1, count - 1) {
                        selectedIndex = max(0, count - 2)
                    }
                }
            )
        case let .snippet(snippet):
            SnippetCardView(
                snippet: snippet,
                indexHint: index < 9 ? index + 1 : nil,
                isSelected: isSelected,
                isHovered: hoveredItemId == snippet.id,
                actions: actions
            )
        }
    }

    private func paste(_ entry: PanelEntry, plainText: Bool) {
        switch entry {
        case let .item(item): actions.paste(.item(item, plainText: plainText))
        case let .snippet(snippet): actions.paste(.text(manager.expandedText(for: snippet)))
        }
    }

    private func filteredEntries() -> [PanelEntry] {
        let query = SearchQuery(searchText)

        if selectedFilter == .snippets {
            return manager.snippets
                .filter { snippet in
                    query.terms.allSatisfy { snippet.title.lowercased().contains($0) || snippet.content.lowercased().contains($0) }
                }
                .map { PanelEntry.snippet($0) }
        }

        let candidates = manager.items.filter(selectedFilter.matches)
        guard !query.isEmpty else { return candidates.map(PanelEntry.item) }

        let boardNames = Dictionary(uniqueKeysWithValues: manager.pinboards.map { ($0.id, $0.name) })
        return candidates
            .enumerated()
            .compactMap { offset, item -> (score: Int, offset: Int, item: ClipboardHistoryItem)? in
                let boardName = item.pinboardID.flatMap { boardNames[$0] }
                return query.score(item, boardName: boardName).map { ($0, offset, item) }
            }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.offset < $1.offset }
            .map { .item($0.item) }
    }
}
