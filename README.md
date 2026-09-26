# 📎 Clipy - Modern macOS Clipboard Manager

A lightweight, high-performance, and beautifully designed clipboard manager for macOS built natively with **Swift** and **SwiftUI**. 

Clipy introduces a card-based horizontal slide-up panel inspired by the Paste app, complete with trackpad gestures, floating Home Bar trigger, global hotkeys, instant search, smart deduplication, automatic pasting, and 1-click app restart.

---

## ✨ Features

- **🎴 Card-Based Horizontal Interface**:
  - Rich preview cards for **Texts**, **Images**, and **Files**, with the real source-app icon, character/line count, image dimensions, and relative timestamps.
  - **Smart content detection**: links (domain + URL), colors (live swatch for `#hex` / `rgb()`), emails, phone numbers, and code (syntax highlighted).
  - Hover actions to add to the paste stack, pin, or delete; right-click for every action.

- **🚀 Multiple Activation Methods**:
  - **Global Hotkey**: `⌘ + Shift + V` by default — **customisable** in Settings › Shortcuts.
  - **Trackpad Swipe Up**, **Floating Home Bar Indicator**, and **Menu Bar Status Item**.

- **⚡ Pasting**:
  - `1`–`9` quick paste, `←` / `→` + `Enter` to navigate and paste, `⌘E` to edit the text before pasting, automatic `⌘V` into the previous app.
  - **Rich text is preserved** (RTF/HTML); **Paste as Plain Text** with `⌥ + Enter` or `⌥`-click.
  - **Paste Transformed**: UPPERCASE, lowercase, Title Case, trim / collapse whitespace, format / minify JSON, URL encode / decode, Base64 encode / decode.
  - **Paste Stack**: queue items with `⇧ + Enter`, then press `⌃⌘V` (customisable) in any app to paste them one by one — ideal for forms.

- **📌 Organise**:
  - **Pinboards**: named, coloured collections (Work, Code, Replies…) shown as tabs; items in a pinboard are never trimmed.
  - **Snippets**: reusable text templates with placeholders — `{date}`, `{time}`, `{datetime}`, `{weekday}`, `{clipboard}`, `{uuid}`.
  - **Quick Look**: press `Space` on a card to preview the full text (with formatting), image (with recognised text), or file list.

- **🔍 Search & Filter**:
  - Fuzzy search across text, file names, source apps, and **text recognised inside images (OCR)**.
  - Filters: `app:safari`, `type:image|text|file|link|color|code|email|phone`, `is:pinned`, `is:rich`, `date:today|yesterday|week|month`, `board:work`.
  - Tabs: **All**, **Texts**, **Images**, **Files**, **Links**, **Colors**, **Code**, **Pinned**, **Snippets**, plus one per pinboard.

- **🔒 Privacy & Local Persistence**:
  - 100% offline and local storage. No network connections or analytics.
  - Skips data marked as concealed/transient by password managers, and ignores **any app you choose** (Keychain Access, Passwords, 1Password, Bitwarden, and LastPass by default).
  - **Retention by age** (1 / 7 / 30 / 90 days or forever) on top of the item limit; pinned and pinboard items are always kept.
  - Image cache size shown in Settings, with one-click removal of unused images.

- **🤖 Shortcuts & Siri (App Intents)**:
  - *Get Latest Clipboard Item*, *Search Clipboard History*, *Save Text to Clipy* (optionally into a pinboard), *Get Snippet*, *Show Clipy*.

- **🔄 Background Persistence**: accessory app with in-app restart, launch at login, and a Settings window that closes without quitting.

---

## ⌨️ Shortcuts & Controls

| Action | Shortcut / Gesture |
| :--- | :--- |
| **Open Clipy** | `⌘ + Shift + V` (customisable), swipe up at bottom edge, or click bottom pill |
| **Close Clipy / Preview** | `Esc`, click the red `✕` button, or click outside the panel |
| **Navigate Cards** | `←` / `→` |
| **Paste Selected Card** | `Enter` or click |
| **Paste as Plain Text** | `⌥ + Enter` or `⌥`-click |
| **Add to / Remove from Paste Stack** | `⇧ + Enter` or the stack button on hover |
| **Paste Next from Stack** | `⌃ + ⌘ + V` in any app (customisable) |
| **Quick Look Preview** | `Space` |
| **Quick Paste Items 1–9** | `1` … `9` |
| **More Actions** | Right-click a card (transform, pinboard, snippet, open link, reveal in Finder) |
| **Open Settings** | Click `⚙` |

---

## 🛠️ Requirements & Building

- **macOS**: 26.4 or later
- **Xcode**: 26.4+ (for the macOS 26.4 SDK)
- **Swift**: 5.9+

### Build & Run via Terminal

```bash
# Clone the repository
git clone https://github.com/AymanOmara/clipy.git
cd Clipy

# Build the project
xcodebuild -scheme Clipy -configuration Debug -destination 'platform=macOS' build

# Run the app
open build/Build/Products/Debug/Clipy.app

# Run the unit tests
xcodebuild test -scheme Clipy -destination 'platform=macOS'
```

Tests run hosted in the app, which detects the test run and uses an isolated history, pasteboard and preferences domain — your real history is never touched.

---

## 🏗️ Architecture Overview

```
Clipy/
├── App & Lifecycle/
│   ├── ClipyApp.swift / AppDelegate.swift  # Entry point, accessory lifecycle, flush on quit
│   ├── AppEnvironment.swift                # Isolated setup when hosting unit tests
│   └── AppLifecycleUtility.swift           # In-app restart & relaunch helper
├── Models/
│   ├── ClipboardHistoryItem.swift          # History item (backward-compatible Codable)
│   ├── ClipboardCapture.swift              # Raw pasteboard content before dedup
│   ├── ContentClassifier.swift             # Link / color / email / phone / code detection
│   ├── Pinboard.swift / Snippet.swift      # Collections and templates (+ placeholder expansion)
│   ├── FilterType.swift / SearchQuery.swift# Tabs, fuzzy search and search filters
│   ├── TextTransform.swift                 # Paste Transformed conversions
│   └── KeyCombo.swift                      # Global shortcut model
├── Services/
│   ├── DiskClipboardStorage.swift          # Debounced background JSON writes, image cache
│   ├── ClipboardMonitor.swift              # Pasteboard observer (rich text, multi-file, exclusions)
│   ├── ExcludedAppsStore.swift             # Ignored apps
│   ├── ImageProcessor.swift                # Off-main hashing, PNG encoding, Vision OCR
│   ├── HotkeyManager.swift / HotkeySettings.swift # Multiple Carbon hotkeys, user shortcuts
│   ├── PasteSimulator.swift / PastePermission.swift
│   └── ClipyAppIntents.swift               # Shortcuts actions
├── Coordination/
│   ├── ClipboardHistoryManager(+Actions).swift # State, dedup, trimming, retention, pinboards, snippets
│   ├── PanelManager(+Paste).swift          # Windows, hotkeys, paste requests, paste stack
│   ├── PasteStack.swift                    # Queue for Paste Next
│   ├── PreviewWindowController.swift       # Quick Look window
│   └── GlobalEventMonitorManager.swift / MenuBarController.swift / SettingsWindowController.swift
└── UI Views/
    ├── HorizontalContentView.swift / PanelKeyboardHandler.swift
    ├── HorizontalHeaderBar.swift / FilterPill.swift
    ├── ClipboardCardView.swift / CardBodyView.swift / CardChrome.swift / CardContextMenu.swift
    ├── SnippetCardView.swift / PreviewView.swift / SyntaxHighlighter.swift
    └── Settings*.swift                     # System Settings–style sidebar: General, Shortcuts, Gestures, Privacy, Snippets, Pinboards, Storage, About
ClipyTests/                                 # Swift Testing unit tests
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Created by [Ayman Omara](https://github.com/AymanOmara)**
