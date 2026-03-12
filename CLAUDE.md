# CLAUDE.md - WhisperKey

## Project Overview
WhisperKey is a native macOS menu bar app that provides push-to-talk voice transcription using a local Whisper model. Hold a hotkey to record, release to transcribe, text is copied to clipboard and pasted into the active field. No cloud, no subscription, no internet.

## Critical Rules

### Execution Model
- **USE SUBAGENTS HEAVILY.** Spawn subagents for each module/file to conserve context.
- After the full build succeeds, do a final verification pass: build clean, check for warnings, confirm all features.

### Code Quality
- Every file has ONE responsibility (SRP). No god classes.
- No force unwraps (`!`) except for IBOutlets. Use guard/let and proper error handling.
- All classes/structs get clear doc comments explaining their purpose.
- Use Swift naming conventions. No abbreviations.
- Keep functions under 30 lines. Extract helpers.
- Use protocols for testability (e.g. `AudioRecording`, `Transcribing`, `TextOutputting`).

### Architecture
- MVVM where applicable. Settings use ObservableObject.
- Managers are singletons only when truly necessary (HotkeyManager, AudioRecorder).
- Use Combine for reactive state where it simplifies code.
- All async work on background threads. UI updates on MainActor.

## Tech Stack
- Swift 5.9+, SwiftUI, macOS 14+ (Sonoma)
- whisper.cpp via Swift Package Manager (https://github.com/ggerganov/whisper.cpp)
- AVFoundation for audio capture
- CGEvent for global hotkeys and simulated paste
- UserDefaults for settings persistence

## Build Commands
```bash
# Build
xcodebuild -project WhisperKey.xcodeproj -scheme WhisperKey -configuration Debug build

# Build and run
xcodebuild -project WhisperKey.xcodeproj -scheme WhisperKey -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/WhisperKey-*/Build/Products/Debug/WhisperKey.app 

# Clean build
xcodebuild -project WhisperKey.xcodeproj -scheme WhisperKey clean build
```

## File Structure
```
WhisperKey/
├── CLAUDE.md                         # This file
├── SPEC.md                           # Full spec (read this first)
├── WhisperKey.xcodeproj/
├── WhisperKey/
│   ├── App/
│   │   ├── WhisperKeyApp.swift       # @main entry, menu bar setup
│   │   └── AppDelegate.swift         # NSApplicationDelegate, lifecycle
│   ├── Managers/
│   │   ├── HotkeyManager.swift       # CGEvent tap, global hotkey capture
│   │   ├── AudioRecorder.swift       # AVAudioEngine, 16kHz mono PCM capture
│   │   ├── WhisperTranscriber.swift  # whisper.cpp wrapper, model loading
│   │   └── TextOutputManager.swift   # NSPasteboard + CGEvent Cmd+V paste
│   ├── UI/
│   │   ├── MenuBarManager.swift      # NSStatusItem, menu construction
│   │   ├── SettingsView.swift        # SwiftUI settings window
│   │   ├── HotkeyRecorderView.swift  # "Press a key" hotkey capture UI
│   │   └── RecordingIndicator.swift  # Floating recording indicator window
│   ├── Models/
│   │   ├── AppSettings.swift         # UserDefaults wrapper, @AppStorage
│   │   └── HotkeyBinding.swift       # Codable hotkey representation
│   ├── Protocols/
│   │   ├── AudioRecording.swift      # Protocol for audio capture
│   │   ├── Transcribing.swift        # Protocol for transcription
│   │   └── TextOutputting.swift      # Protocol for clipboard/paste
│   ├── Utilities/
│   │   ├── PermissionManager.swift   # Mic + Accessibility permission checks
│   │   └── ModelDownloader.swift     # Downloads whisper model from HuggingFace
│   └── Resources/
│       ├── Info.plist
│       ├── Assets.xcassets/
│       └── WhisperKey.entitlements
```

