# 📎 Clipy - Modern macOS Clipboard Manager

A lightweight, high-performance, and beautifully designed clipboard manager for macOS built natively with **Swift** and **SwiftUI**. 

Clipy introduces a card-based horizontal slide-up panel inspired by the Paste app, complete with trackpad gestures, floating Home Bar trigger, global hotkeys, instant search, smart deduplication, automatic pasting, and 1-click app restart.

---

## ✨ Features

- **🎴 Card-Based Horizontal Interface**:
  - Displays rich visual preview cards for **Texts**, **Images**, and **Files**.
  - Shows metadata including source application icons, character/line count, image dimensions, and relative timestamps.
  - Hover action shortcuts to pin, copy, or delete items.
  - Dedicated **`✕` close button** with smooth red hover highlight.

- **🚀 Multiple Activation Methods**:
  - **Global Hotkey**: Press `⌘ + Shift + V` from anywhere.
  - **Trackpad Swipe Up**: Swipe up with two fingers near the bottom edge of the screen.
  - **Floating Home Bar Indicator**: Subtle, translucent pill indicator at the bottom center of the screen.
  - **Menu Bar Status Item**: Left-click to toggle, right-click for context menu (Toggle, Restart, Quit).

- **⚡ Instant Auto-Pasting & Keyboard Shortcuts**:
  - Press `1` through `9` for instant 1-click paste of recent cards.
  - Navigate effortlessly using `←` / `→` arrow keys and `Enter`.
  - Automatically activates the target application and synthesizes `⌘ + V`.

- **🔍 Search & Filter Categories**:
  - Real-time search across text content, filenames, and source applications.
  - Category tabs: **All**, **Texts**, **Images**, **Files**, and **Pinned**.

- **🔄 In-App Restart & Background Persistence**:
  - `AppDelegate` lifecycle management keeps the accessory app alive persistently.
  - 1-click **Restart App** button in Preferences and Menu Bar context menu.
  - Clean single-close Preferences panel that dismisses without quitting the background service.

- **🔒 Privacy & Local Persistence**:
  - 100% offline and local storage. No network connections or analytics.
  - History stored in `~/Library/Application Support/self.Clipy/`.
  - Image assets cached in `~/Library/Caches/self.Clipy/`.

- **📐 Clean Architecture & SOLID Design**:
  - Fully decoupled services (`DiskClipboardStorage`, `ClipboardMonitor`, `HotkeyManager`, `PasteSimulator`).
  - Modular SwiftUI views (all files strictly under 180 lines of clean code).

---

## ⌨️ Shortcuts & Controls

| Action | Shortcut / Gesture |
| :--- | :--- |
| **Open Clipy** | `⌘ + Shift + V` or swipe up at bottom edge or click bottom pill |
| **Close Clipy** | `Esc`, click top-right red `✕` button, or click outside the panel |
| **Navigate Cards** | `←` Left Arrow / `→` Right Arrow |
| **Paste Selected Card** | `Enter` / `Return` or click card |
| **Quick Paste Items 1–9** | `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9` |
| **Open Preferences** | Click `⚙` Settings icon |
| **Restart Clipy** | Click **Restart App** in Preferences or Right-click Menu Bar icon |

---

## 🛠️ Requirements & Building

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0+
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
```

---

## 🏗️ Architecture Overview

```
Clipy/
├── App & Lifecycle/
│   ├── ClipyApp.swift                      # SwiftUI App entry point
│   ├── AppDelegate.swift                   # Accessory lifecycle & termination guard
│   └── AppLifecycleUtility.swift           # In-app restart & relaunch helper
├── Core & Models/
│   ├── ClipboardHistoryItem.swift          # Data model and preview formatters
│   └── FilterType.swift                    # Category filtering definitions
├── Services/
│   ├── Storage/
│   │   ├── ClipboardStorageProtocol.swift   # Storage interface (DIP)
│   │   └── DiskClipboardStorage.swift       # JSON & cached asset persistence
│   ├── Monitoring/
│   │   ├── ClipboardMonitoringProtocol.swift# Pasteboard monitor interface
│   │   └── ClipboardMonitor.swift          # System pasteboard observer
│   ├── Hotkey/
│   │   ├── HotkeyManager.swift              # Carbon global hotkey manager
│   │   └── HotkeyManagingProtocol.swift     # Hotkey interface abstraction
│   └── Automation/
│       ├── PasteSimulator.swift             # CGEvent synthetic keystroke injector
│       └── PasteSimulatingProtocol.swift    # Keystroke simulation interface
├── State & Coordination/
│   ├── ClipboardHistoryManager.swift        # Domain state, deduplication & trimming
│   ├── ClipboardHistoryManager+Actions.swift# Pasteboard actions & pin management
│   ├── PanelManager.swift                   # Coordinator managing windows & lifecycle
│   ├── PanelPresentationAnimator.swift      # Spring slide animations
│   ├── GlobalEventMonitorManager.swift      # System-wide mouse & keyboard monitor
│   ├── MenuBarController.swift              # Status item & right-click menu
│   └── SettingsWindowController.swift       # Preferences NSPanel controller
└── UI Views/
    ├── HorizontalContentView.swift          # Main horizontal card panel
    ├── HorizontalHeaderBar.swift            # Search bar, filter pills & red close button
    ├── ClipboardCardView.swift              # History item preview card
    ├── CardBodyView.swift                   # Dynamic body (Text/Image/File)
    ├── PillHandleView.swift                 # Bottom Home Bar capsule handle
    ├── EmptyClipboardView.swift             # Placeholder empty state
    ├── VisualEffectView.swift               # NSVisualEffectView glassmorphism wrapper
    └── Settings/                            # Preferences (General, Gestures, Storage)
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Created by [Ayman Omara](https://github.com/AymanOmara)**
