//
//  SettingsStorageSection.swift
//  Clipy
//
//  Created by Ayman Omara on 08/08/2026.
//

import SwiftUI

struct SettingsStorageSection: View {
    let manager: ClipboardHistoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data & Actions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Total Items in History")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(manager.items.count)")
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Pinned Items")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(manager.items.filter { $0.isPinned }.count)")
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                
                Divider().padding(.vertical, 4)
                
                HStack(spacing: 12) {
                    Button(action: {
                        manager.clearHistory(includePinned: false)
                    }) {
                        Text("Clear Unpinned")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        manager.clearHistory(includePinned: true)
                    }) {
                        Text("Clear All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider().padding(.vertical, 4)
                
                HStack(spacing: 12) {
                    Button(action: {
                        AppLifecycleUtility.restartApp()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart App")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                            Text("Quit Clipy")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.06))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
