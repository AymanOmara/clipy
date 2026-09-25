//
//  ClipboardCardView.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI
import AppKit

/// Standalone card component representing a clipboard item with header, body preview, footer, and hover actions.
struct ClipboardCardView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    @Environment(PasteStack.self) var pasteStack

    let item: ClipboardHistoryItem
    let indexHint: Int?
    let isSelected: Bool
    let isHovered: Bool
    let actions: PanelActions
    let onDelete: () -> Void

    var body: some View {
        CardChrome(isSelected: isSelected, isHovered: isHovered) {
            VStack(spacing: 0) {
                cardHeader
                Divider().opacity(0.3)
                CardBodyView(item: item)
                Spacer(minLength: 0)
                cardFooter
            }
        } hoverContent: {
            hoverActions
        }
        .contextMenu {
            CardContextMenu(item: item, actions: actions, onDelete: onDelete)
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                if let icon = AppIconCache.icon(for: item.sourceBundleID) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Text(item.sourceAppName ?? "Unknown App")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let board = manager.pinboard(for: item) {
                Circle()
                    .fill(board.color)
                    .frame(width: 7, height: 7)
                    .help("In pinboard “\(board.name)”")
            }

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
            }

            Image(systemName: item.type == .text ? item.kind.iconName : item.type.iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(item.type.themeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var cardFooter: some View {
        HStack(spacing: 6) {
            Text(item.displayTime)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.8))

            if item.hasRichText {
                CardBadge(text: "Aa", help: "Rich text: ⌥↩ or ⌥-click pastes as plain text")
            }
            if item.ocrText != nil {
                CardBadge(text: "OCR", help: "Text recognised in this image is searchable")
            }

            Spacer()

            if let position = pasteStack.position(of: item) {
                CardBadge(text: "Stack \(position)", tint: .orange, help: "Pasted in order with the Paste Next shortcut")
            }

            if let index = indexHint {
                CardBadge(text: "\(index)", tint: isSelected ? .accentColor : nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var hoverActions: some View {
        HStack(spacing: 4) {
            CardHoverButton(
                systemImage: pasteStack.contains(item) ? "square.stack.3d.up.slash.fill" : "square.stack.3d.up.fill",
                background: .orange.opacity(0.85),
                help: pasteStack.contains(item) ? "Remove from Paste Stack" : "Add to Paste Stack (⇧↩)"
            ) { pasteStack.toggle(item) }

            CardHoverButton(
                systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill",
                background: .black.opacity(0.6),
                help: item.isPinned ? "Unpin Item" : "Pin Item"
            ) { manager.togglePin(for: item) }

            CardHoverButton(systemImage: "trash.fill", background: .red.opacity(0.8), help: "Delete Item", action: onDelete)
        }
        .padding(8)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
