//
//  ContentView.swift
//  Clipy
//
//  Created by Ayman Omara on 07/08/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var hoveredItemId: UUID? = nil
    @State private var isShowingSettings = false
    @State private var showToast = false
    @State private var toastText = ""
    
    var body: some View {
        ZStack {
            if isShowingSettings {
                SettingsView(isPresented: $isShowingSettings)
                    .transition(.move(edge: .trailing))
            } else {
                mainClipboardView
                    .transition(.move(edge: .leading))
            }
            
            if showToast {
                ContentToastOverlay(text: toastText)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: showToast)
                    .zIndex(100)
            }
        }
        .frame(width: 360, height: 480)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }
    
    private var mainClipboardView: some View {
        VStack(spacing: 0) {
            ContentSearchBar(searchText: $searchText)
            ContentCategoryFilterBar(selectedFilter: $selectedFilter)
            Divider()
            itemsList
            Divider()
            footerBar
        }
    }
    
    @ViewBuilder
    private var itemsList: some View {
        let filteredItems = getFilteredItems()
        
        if filteredItems.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "paperclip.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(searchText.isEmpty ? "No clipboard items yet" : "No matches found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(searchText.isEmpty ? "Copy something and it will appear here." : "Try adjusting your search query.")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            }
        } else {
            List {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    let shortcutKey: KeyEquivalent? = index < 9 ? KeyEquivalent(Character(UnicodeScalar(49 + index)!)) : nil
                    
                    ClipboardRowView(
                        item: item,
                        indexHint: index < 9 ? index + 1 : nil,
                        isHovered: hoveredItemId == item.id,
                        onCopy: { handleCopyAction(item) },
                        onDelete: { manager.deleteItem(item) },
                        onTogglePin: { manager.togglePin(for: item) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { handleCopyAction(item) }
                    .onHover { hovering in hoveredItemId = hovering ? item.id : nil }
                    .background(
                        Group {
                            if let key = shortcutKey {
                                Button("") { handleCopyAction(item) }
                                    .keyboardShortcut(key, modifiers: .command)
                                    .opacity(0)
                                    .frame(width: 0, height: 0)
                            }
                        }
                    )
                }
            }
            .listStyle(.plain)
        }
    }
    
    private var footerBar: some View {
        HStack {
            Button(action: {
                withAnimation { isShowingSettings = true }
            }) {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Open Preferences")
            
            Spacer()
            
            #if os(macOS)
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.title3)
                    .foregroundColor(.red.opacity(0.8))
                    .padding(8)
                    .background(Color.red.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Quit Clipy")
            #endif
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.02))
    }
    
    private func getFilteredItems() -> [ClipboardHistoryItem] {
        manager.items.filter { item in
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let lower = searchText.lowercased()
                let contentMatch = item.stringValue?.lowercased().contains(lower) ?? false
                let fileMatch = item.fileName?.lowercased().contains(lower) ?? false
                let appMatch = item.sourceAppName?.lowercased().contains(lower) ?? false
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
    
    private func handleCopyAction(_ item: ClipboardHistoryItem) {
        manager.copyToClipboard(item)
        let itemTypeLabel = item.type == .text ? "Text" : (item.type == .image ? "Image" : "File link")
        toastText = "✓ \(itemTypeLabel) copied to clipboard"
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            showToast = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { showToast = false }
        }
    }
}
