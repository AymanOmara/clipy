//
//  PillHandleView.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

/// Sleek iOS/macOS style Home Bar pill indicator.
struct PillHandleView: View {
    @State private var isHovered = false
    var onClick: () -> Void
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.primary.opacity(isHovered ? 0.45 : 0.22))
                .frame(width: isHovered ? 140 : 110, height: isHovered ? 6 : 4)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onClick()
        }
    }
}
