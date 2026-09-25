//
//  SettingsSnippetsSection.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import SwiftUI

/// Create, edit and delete snippets; they appear in the panel's Snippets tab.
struct SettingsSnippetsSection: View {
    let manager: ClipboardHistoryManager
    @State private var editing: Snippet?
    @State private var pendingDeletion: Snippet?

    var body: some View {
        Form {
            Section {
                if manager.snippets.isEmpty {
                    Text("No snippets yet. Save text you paste often, like an email signature or an address.")
                        .foregroundStyle(.secondary)
                }
                ForEach(manager.snippets) { snippet in
                    LabeledContent {
                        HStack(spacing: 12) {
                            Button("Edit") { editing = snippet }
                            Button("Delete", role: .destructive) { pendingDeletion = snippet }
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    } label: {
                        Text(snippet.title)
                        Text(snippet.content.replacingOccurrences(of: "\n", with: " "))
                            .lineLimit(1)
                    }
                }
                Button("New Snippet…") { editing = Snippet(title: "", content: "") }
                    .buttonStyle(.borderless)
            } footer: {
                Text("Paste snippets from the Snippets tab, or right-click a text item and choose Save as Snippet.")
                    .settingsFooter()
            }
        }
        .sheet(item: $editing) { snippet in
            SnippetEditorView(snippet: snippet, isNew: !manager.snippets.contains { $0.id == snippet.id }) { saved in
                manager.saveSnippet(saved)
            }
        }
        .confirmationDialog(
            "Delete “\(pendingDeletion?.title ?? "")”?",
            isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
            presenting: pendingDeletion
        ) { snippet in
            Button("Delete Snippet", role: .destructive) { manager.deleteSnippet(snippet) }
        } message: { _ in
            Text("This can't be undone.")
        }
    }
}

struct SnippetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var snippet: Snippet
    let isNew: Bool
    let onSave: (Snippet) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Name", text: $snippet.title, prompt: Text("e.g. Email signature"))
                }
                Section {
                    TextEditor(text: $snippet.content)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("Text")
                } footer: {
                    Text("Placeholders are filled in when you paste: " + SnippetExpander.placeholders.map(\.token).joined(separator: "  "))
                        .settingsFooter()
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(isNew ? "Add Snippet" : "Save Changes") {
                    if snippet.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        snippet.title = String(snippet.content.prefix(40))
                    }
                    onSave(snippet)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(snippet.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .frame(width: 460, height: 400)
    }
}
