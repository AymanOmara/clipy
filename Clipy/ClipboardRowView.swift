//
//  ClipboardRowView.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI
import AppKit

struct ClipboardRowView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    let item: ClipboardHistoryItem
    let indexHint: Int?
    let isHovered: Bool
    
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Item Icon representation
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.type.themeColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    if item.type == .image {
                        if let img = manager.loadImage(for: item) {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(item.type.themeColor)
                        }
                    } else {
                        Image(systemName: item.type.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(item.type.themeColor)
                    }
                }
                
                // Item Content Details
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(item.displayTitle)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        if let appName = item.sourceAppName {
                            Text(appName)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.primary.opacity(0.06))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                        
                        Text(item.displaySubtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right indicators or Hover Quick Action buttons
                if isHovered {
                    HStack(spacing: 4) {
                        Button(action: onTogglePin) {
                            Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? "Unpin Item" : "Pin Item")
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red.opacity(0.8))
                                .padding(6)
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Delete Item")
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(item.displayTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if let index = indexHint {
                            Text("⌘\(index)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(3)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            
            Divider()
                .padding(.leading, 64)
                .opacity(isHovered ? 0 : 0.5)
        }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
