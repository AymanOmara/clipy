//
//  HorizontalHeaderBar.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct HorizontalHeaderBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: FilterType
    var onResetSelection: () -> Void
    var onOpenSettings: () -> Void
    var onClose: () -> Void
    
    @State private var isCloseHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            brandTitle
            searchField
            filterPills
            Spacer()
            HStack(spacing: 8) {
                preferencesButton
                closeButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
    
    private var brandTitle: some View {
        HStack(spacing: 8) {
            Image(systemName: "paperclip")
                .font(.title3)
                .foregroundColor(.accentColor)
            Text("Clipy")
                .font(.headline)
                .fontWeight(.bold)
        }
    }
    
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search history...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onResetSelection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .frame(maxWidth: 320)
    }
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FilterType.allCases) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selectedFilter = filter
                            onResetSelection()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            Text(filter.rawValue)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.accentColor : Color.primary.opacity(0.04))
                        )
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var preferencesButton: some View {
        Button(action: onOpenSettings) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.primary.opacity(0.04))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Open Preferences")
    }
    
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isCloseHovered ? .white : .red)
                .padding(8)
                .background(isCloseHovered ? Color.red.opacity(0.9) : Color.red.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isCloseHovered = hovering
            }
        }
        .help("Close Panel (Esc)")
    }
}
