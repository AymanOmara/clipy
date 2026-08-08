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
                if let text = item.stringValue {
                    Text(text)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.85))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(10)
                }
            case .image:
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
            case .file:
                HStack(spacing: 12) {
                    Image(systemName: "doc.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(item.type.themeColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.fileName ?? "File")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(item.displaySubtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .frame(height: 100)
    }
}
