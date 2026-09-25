//
//  CardChrome.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI
import AppKit

/// Shared card frame (background, selection ring, hover scale) for history and snippet cards.
struct CardChrome<Content: View, HoverContent: View>: View {
    let isSelected: Bool
    let isHovered: Bool
    @ViewBuilder let content: Content
    @ViewBuilder let hoverContent: HoverContent

    static var cardWidth: CGFloat { 240 }
    static var cardHeight: CGFloat { 160 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(isSelected ? 0.95 : 0.65))
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

            content

            if isHovered {
                hoverContent
            }
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isHovered)
    }
}

struct CardBadge: View {
    let text: String
    var tint: Color? = nil
    var help: String? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(tint == nil ? .secondary : .white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint ?? Color.primary.opacity(0.06))
            .clipShape(Capsule())
            .help(help ?? "")
    }
}

struct CardHoverButton: View {
    let systemImage: String
    let background: Color
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10))
                .foregroundColor(.white)
                .padding(5)
                .background(background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
