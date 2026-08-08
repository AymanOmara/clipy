//
//  EmptyClipboardView.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct EmptyClipboardView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "paperclip.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text(searchText.isEmpty ? "No clipboard items yet" : "No matches found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "Anything you copy will slide up here." : "Try adjusting your search query.")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}
