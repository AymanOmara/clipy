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
    let item: ClipboardHistoryItem
    let indexHint: Int?
    let isSelected: Bool
    let isHovered: Bool
    
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    
    private let cardWidth: CGFloat = 240
    private let cardHeight: CGFloat = 160
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(isSelected ? 0.95 : 0.65))
                .frame(width: cardWidth, height: cardHeight)
                .shadow(
                    color: isSelected ? Color.accentColor.opacity(0.25) : Color.black.opacity(0.06),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
            
            VStack(spacing: 0) {
                cardHeader
                Divider().opacity(0.3)
                CardBodyView(item: item)
                Spacer(minLength: 0)
                cardFooter
            }
            .frame(width: cardWidth, height: cardHeight)
            
            if isHovered {
                hoverActions
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isHovered)
    }
    
    private var cardHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "app.dashed")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(item.sourceAppName ?? "Unknown App")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
            }
            
            Image(systemName: item.type.iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(item.type.themeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var cardFooter: some View {
        HStack {
            Text(item.displayTime)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.8))
            
            Spacer()
            
            if let index = indexHint {
                Text("\(index)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    private var hoverActions: some View {
        HStack(spacing: 4) {
            Button(action: onTogglePin) {
                Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(item.isPinned ? "Unpin Item" : "Pin Item")
            
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete Item")
        }
        .padding(8)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
