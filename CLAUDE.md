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

---

## Bundle Identifier
`com.whisperkey.app`

---

## Signing — CRITICAL

**The app must be signed with a real Developer identity for microphone permission to work.**

macOS 15 silently blocks microphone permission requests from ad-hoc signed apps — no prompt
appears, the app never shows up in the Microphone list, and TCC shows "Denied" with no way
to fix it via `tccutil`. This is not a code bug.

**How to set up signing (one-time):**
1. Open Xcode → click the `WhisperKey` project in the navigator
2. Select the `WhisperKey` target → **Signing & Capabilities**
3. Set **Team** to your personal Apple ID team (`mjohnson@hopskipdrive.com`)
4. Xcode manages the rest automatically

**Available signing identity:** `Apple Development: mjohnson@hopskipdrive.com (G4TYJC77K2)`

Once signing is configured, permissions work normally.

---

## Build & Install

**The golden path — do this exactly:**

1. Build and run from Xcode (Cmd+R) to get permission prompts
2. Grant Microphone and Accessibility when prompted
3. Copy that exact Xcode binary to /Applications — **DO NOT reset permissions**
4. Launch `/Applications/WhisperKey.app` — permissions carry over via signing identity

```bash
# After granting permissions via Xcode run:
rm -rf /Applications/WhisperKey.app
cp -R ~/Library/Developer/Xcode/DerivedData/WhisperKey-*/Build/Products/Debug/WhisperKey.app \
  /Applications/WhisperKey.app
```

**DO NOT run `tccutil reset` after copying.** Permissions are tied to the signing identity,
not the path. Same cert = same grant. Resetting destroys it and the mic prompt will never
reappear (macOS 15 silently blocks re-prompted mic requests for this app).

---

## Resetting Permissions

### Reset everything (recommended after any reinstall)

```bash
tccutil reset All com.whisperkey.app
```

### Reset individual permissions

```bash
tccutil reset Microphone com.whisperkey.app
tccutil reset Accessibility com.whisperkey.app
```

> **Note:** Each command prints two "Successfully reset" lines — user TCC DB and system
> TCC DB. That's expected.

---

## Permission Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| No mic prompt ever appears, app not in Microphone list | App is ad-hoc signed — macOS 15 silently blocks unsigned apps from requesting mic | Set Team in Xcode Signing & Capabilities, rebuild |
| Status tab shows "Denied" after enabling toggle in System Settings | TCC has a stale denial record | `tccutil reset All com.whisperkey.app` + relaunch |
| Transcription outputs "you" or short random words | Whisper hallucinating on silence — mic not actually capturing audio | Fix mic permission first |
| Hotkey does nothing after granting Accessibility | App started before permission was granted | App auto-retries every 2s — wait a moment |
| Two WhisperKey entries in System Settings | Old build + new build both registered | `tccutil reset All` clears both; relaunch registers fresh |

---

## Running from Xcode vs /Applications

macOS tracks permissions **per executable path + signing identity**.

- The Xcode debug build and `/Applications/WhisperKey.app` are treated as separate apps
  by TCC — each needs its own permission grant.
- For daily use: run `/Applications/WhisperKey.app` (release build).
- For development: run from Xcode (Cmd+R) — the Xcode build uses your Developer signing
  and gets its own TCC entry. Grant permissions once; they persist across Xcode runs.
- **Do not** use `tccutil reset` between Xcode runs during development — you'll have to
  re-approve every time.
