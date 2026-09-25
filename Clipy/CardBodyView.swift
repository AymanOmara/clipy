//
//  CardBodyView.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI
import AppKit

struct CardBodyView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    let item: ClipboardHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch item.type {
            case .text:
                textBody(item.stringValue ?? "")
            case .image:
                imageBody
            case .file:
                fileBody
            }
        }
        .frame(height: 100)
    }

    @ViewBuilder
    private func textBody(_ text: String) -> some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch item.kind {
        case .color:
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ContentClassifier.color(from: trimmed) ?? .clear)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.15)))
                    .frame(width: 64, height: 64)
                Text(trimmed)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .textSelection(.disabled)
                Spacer()
            }
            .padding(12)
        case .url:
            iconRow(systemImage: "link.circle.fill", tint: .blue,
                    title: URL(string: trimmed)?.host() ?? trimmed, subtitle: trimmed)
        case .email:
            iconRow(systemImage: "envelope.circle.fill", tint: .teal, title: trimmed, subtitle: "Email address")
        case .phone:
            iconRow(systemImage: "phone.circle.fill", tint: .green, title: trimmed, subtitle: "Phone number")
        case .code:
            Text(SyntaxHighlighter.highlight(String(text.prefix(600))))
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
        case .plain:
            Text(text.prefix(600))
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.primary.opacity(0.85))
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
        }
    }

    @ViewBuilder
    private var imageBody: some View {
        if let image = manager.loadImage(for: item) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 216, height: 90)
                .cornerRadius(6)
                .padding(8)
        } else {
            VStack {
                Spacer()
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundColor(item.type.themeColor.opacity(0.5))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var fileBody: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let first = item.allFileURLs.first {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: first.path))
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                if item.allFileURLs.count > 1 {
                    CardBadge(text: "\(item.allFileURLs.count)", tint: .green)
                        .offset(x: 6, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.displaySubtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func iconRow(systemImage: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 30))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
