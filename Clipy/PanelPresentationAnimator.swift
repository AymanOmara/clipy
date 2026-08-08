//
//  PanelPresentationAnimator.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import Cocoa

/// Handles frame calculations and animations for presenting and dismissing the floating panel.
final class PanelPresentationAnimator {
    private(set) var isAnimating = false
    
    func slideUp(panel: NSPanel, onComplete: @escaping () -> Void) {
        guard !isAnimating else { return }
        isAnimating = true
        
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let targetFrame = NSRect(
            x: panel.frame.origin.x,
            y: screenFrame.minY + 16,
            width: panel.frame.width,
            height: panel.frame.height
        )
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 1.0
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
            onComplete()
        })
    }
    
    func slideDown(panel: NSPanel, onComplete: @escaping () -> Void) {
        guard !isAnimating else { return }
        isAnimating = true
        
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let targetFrame = NSRect(
            x: panel.frame.origin.x,
            y: screenFrame.minY - panel.frame.height,
            width: panel.frame.width,
            height: panel.frame.height
        )
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
            onComplete()
        })
    }
}
