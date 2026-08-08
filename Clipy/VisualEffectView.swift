//
//  VisualEffectView.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI
import AppKit

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#else
struct VisualEffectView: View {
    let material: Any
    let blendingMode: Any
    
    init(material: Any, blendingMode: Any) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    var body: some View {
        Color(.systemBackground).opacity(0.85)
    }
}
#endif
