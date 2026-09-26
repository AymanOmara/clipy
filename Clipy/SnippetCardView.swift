//
//  SnippetCardView.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// Card for a saved snippet in the Snippets tab; pasting expands its placeholders.
struct SnippetCardView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    
    let snippet: Snippet
    let indexHint: Int?
    let isSelected: Bool
    let isHovered: Bool
    let actions: PanelActions
    
    var body: some View {
        CardChrome(isSelected: isSelected, isHovered: isHovered) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "text.badge.star")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text(snippet.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider().opacity(0.3)
                
                Text(snippet.content)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
                
                HStack {
                    if snippet.content.contains("{") {
                        CardBadge(text: "{ }", help: "Placeholders are filled in when pasted")
                    }
                    Spacer()
                    if let indexHint {
                        CardBadge(text: "\(indexHint)", tint: isSelected ? .accentColor : nil)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        } hoverContent: {
            CardHoverButton(systemImage: "trash.fill", background: .red.opacity(0.8), help: "Delete Snippet") {
                manager.deleteSnippet(snippet)
            }
            .padding(8)
        }
        .contextMenu {
            Button("Paste") { actions.paste(.text(manager.expandedText(for: snippet))) }
            Button("Edit & Paste…") { actions.editAndPaste(manager.expandedText(for: snippet)) }
            Button("Quick Look") { actions.preview(.snippet(snippet)) }
            Divider()
            Button("Delete Snippet", role: .destructive) { manager.deleteSnippet(snippet) }
        }
    }
}
