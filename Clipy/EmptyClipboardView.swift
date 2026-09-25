//
//  EmptyClipboardView.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct EmptyClipboardView: View {
    let searchText: String
    var isSnippets: Bool = false
    
    private var title: String {
        if !searchText.isEmpty { return "No matches found" }
        return isSnippets ? "No snippets yet" : "No clipboard items yet"
    }
    
    private var message: String {
        if !searchText.isEmpty { return "Try adjusting your search query." }
        return isSnippets
            ? "Right-click a text card and choose Save as Snippet, or add one in Settings."
            : "Anything you copy will slide up here."
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: isSnippets ? "text.badge.star" : "paperclip.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}
