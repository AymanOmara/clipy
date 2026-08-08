//
//  HorizontalContentView.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import SwiftUI
import AppKit

/// Primary horizontal card container view displaying clipboard history, search, and category filters.
struct HorizontalContentView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var hoveredItemId: UUID? = nil
    @State private var selectedIndex: Int = 0
    @FocusState private var isListFocused: Bool
    
    var onCopyAndPaste: (ClipboardHistoryItem) -> Void
    var onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HorizontalHeaderBar(
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                onResetSelection: { selectedIndex = 0 },
                onOpenSettings: onOpenSettings
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
    }
    
    @ViewBuilder
    private var cardsContainer: some View {
        let filteredItems = getFilteredItems()
        
        if filteredItems.isEmpty {
            EmptyClipboardView(searchText: searchText)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardCardView(
                                item: item,
                                indexHint: index < 9 ? index + 1 : nil,
                                isSelected: index == selectedIndex && isListFocused,
                                isHovered: hoveredItemId == item.id,
                                onCopy: { onCopyAndPaste(item) },
                                onDelete: {
                                    manager.deleteItem(item)
                                    if selectedIndex >= max(1, filteredItems.count - 1) {
                                        selectedIndex = max(0, filteredItems.count - 2)
                                    }
                                },
                                onTogglePin: { manager.togglePin(for: item) }
                            )
                            .id(index)
                            .onTapGesture {
                                selectedIndex = index
                                onCopyAndPaste(item)
                            }
                            .onHover { hovering in
                                hoveredItemId = hovering ? item.id : nil
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
            .onKeyPress(.leftArrow) {
                if selectedIndex > 0 { selectedIndex -= 1; return .handled }
                return .ignored
            }
            .onKeyPress(.rightArrow) {
                if selectedIndex < filteredItems.count - 1 { selectedIndex += 1; return .handled }
                return .ignored
            }
            .onKeyPress(.return) {
                if selectedIndex < filteredItems.count { onCopyAndPaste(filteredItems[selectedIndex]); return .handled }
                return .ignored
            }
            .onKeyPress(action: { press in
                if let char = press.characters.first, let digit = Int(String(char)), digit >= 1 && digit <= 9 {
                    let idx = digit - 1
                    if idx < filteredItems.count { onCopyAndPaste(filteredItems[idx]); return .handled }
                }
                return .ignored
            })
            .onAppear {
                isListFocused = true
            }
        }
    }
    
    private func getFilteredItems() -> [ClipboardHistoryItem] {
        manager.items.filter { item in
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                let contentMatch = item.stringValue?.lowercased().contains(query) ?? false
                let fileMatch = item.fileName?.lowercased().contains(query) ?? false
                let appMatch = item.sourceAppName?.lowercased().contains(query) ?? false
                matchesSearch = contentMatch || fileMatch || appMatch
            }
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .text: matchesFilter = item.type == .text
            case .image: matchesFilter = item.type == .image
            case .file: matchesFilter = item.type == .file
            case .pinned: matchesFilter = item.isPinned
            }
            
            return matchesSearch && matchesFilter
        }
    }
}
