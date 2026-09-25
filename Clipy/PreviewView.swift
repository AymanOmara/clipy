//
//  PreviewView.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI
import AppKit

/// Full-size content of a history item or snippet, shown by `PreviewWindowController`.
struct PreviewView: View {
    @Environment(ClipboardHistoryManager.self) var manager
    let entry: PanelEntry
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Preview (Space)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var title: String {
        switch entry {
        case let .item(item): return item.displayTitle
        case let .snippet(snippet): return snippet.title
        }
    }

    private var subtitle: String {
        switch entry {
        case let .item(item): return [item.sourceAppName, item.displaySubtitle].compactMap { $0 }.joined(separator: " · ")
        case .snippet: return "Snippet"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch entry {
        case let .snippet(snippet):
            textView(AttributedString(snippet.content))
        case let .item(item):
            switch item.type {
            case .text: textView(richText(for: item))
            case .image: imageView(for: item)
            case .file: fileList(for: item)
            }
        }
    }

    private func richText(for item: ClipboardHistoryItem) -> AttributedString {
        if let rtf = item.rtfData,
           let attributed = NSAttributedString(rtf: rtf, documentAttributes: nil),
           let converted = try? AttributedString(attributed, including: \.appKit) {
            return converted
        }
        if item.kind == .code, let text = item.stringValue {
            return SyntaxHighlighter.highlight(String(text.prefix(20_000)))
        }
        return AttributedString(item.stringValue ?? "")
    }

    private func textView(_ text: AttributedString) -> some View {
        ScrollView {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(16)
        }
    }

    private func imageView(for item: ClipboardHistoryItem) -> some View {
        HStack(spacing: 0) {
            if let image = manager.loadImage(for: item) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if let ocr = item.ocrText {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recognised Text")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(ocr)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
                .frame(width: 240)
            }
        }
    }

    private func fileList(for item: ClipboardHistoryItem) -> some View {
        List(item.allFileURLs, id: \.self) { url in
            HStack(spacing: 10) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                    Text(url.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}
