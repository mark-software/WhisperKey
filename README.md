# WhisperKey

**Push-to-talk voice transcription for macOS. 100% local. No cloud. No subscription.**

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

## What It Does

WhisperKey lives in your menu bar and turns speech into text with a single hotkey. Hold the key, speak, release — your words appear wherever your cursor is. All transcription runs locally on your Mac using [whisper.cpp](https://github.com/ggerganov/whisper.cpp), so nothing ever leaves your machine.

<!-- TODO: Add demo GIF -->
<!-- ![WhisperKey Demo](docs/demo.gif) -->

## Features

- **Push-to-talk** with configurable global hotkey (default: Right Option)
- **Local transcription** via whisper.cpp — base.en and small.en models
- **Auto-paste** into the active text field + clipboard copy
- **Floating recording indicator** — visual feedback while recording
- **Model auto-download** from HuggingFace on first launch
- **Launch at login** support
- **~3s latency** for 10s of speech on Apple Silicon

## Requirements

- macOS 14+ (Sonoma)
- Xcode 15+ (to build from source)
- Microphone permission
- Accessibility permission (for global hotkey and simulated paste)

## Installation

### Download

Download the latest release from [GitHub Releases](https://github.com/markymark/WhisperKey/releases).

<!-- TODO: Update with actual release URL -->

### Build from Source

```bash
git clone https://github.com/markymark/WhisperKey.git
cd WhisperKey
open WhisperKey.xcodeproj
```

Then hit **Cmd+R** in Xcode to build and run.

## Usage

1. Launch WhisperKey — it appears as a microphone icon in your menu bar
2. Grant **Microphone** and **Accessibility** permissions when prompted
3. The Whisper model downloads automatically on first launch (~150 MB for base.en)
4. **Hold your hotkey** (default: Right Option), speak, then **release**
5. Transcribed text is pasted into the active field and copied to your clipboard

## Permissions

WhisperKey needs two permissions to function:

| Permission | Why | How to Grant |
|---|---|---|
| **Microphone** | To capture your voice | macOS prompts automatically on first use |
| **Accessibility** | To capture the global hotkey and simulate Cmd+V paste | System Settings → Privacy & Security → Accessibility → Enable WhisperKey |

WhisperKey will guide you through granting these on first launch.

## Configuration

Open **Settings** from the menu bar icon to configure:

- **Hotkey** — Click "Record Shortcut" to set a custom push-to-talk key
- **Model** — Choose between base.en (faster, ~150 MB) and small.en (more accurate, ~500 MB)
- **Auto-paste** — Toggle whether transcribed text is automatically pasted
- **Sound effects** — Toggle audio feedback for start/stop recording
- **Launch at login** — Start WhisperKey when you log in

## Architecture

WhisperKey follows MVVM with protocol-based abstractions for testability. Key components:

- **HotkeyManager** — CGEvent tap for global hotkey capture
- **AudioRecorder** — AVAudioEngine capture at 16kHz mono PCM
- **WhisperTranscriber** — whisper.cpp integration for local inference
- **TextOutputManager** — NSPasteboard + simulated Cmd+V paste

See [SPEC.md](SPEC.md) for the full specification and [CLAUDE.md](CLAUDE.md) for build instructions and project structure.

## Contributing

Contributions are welcome!

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Open a Pull Request

### Code Quality Rules

- Every file has **one responsibility** (SRP)
- No force unwraps (`!`) except for IBOutlets
- Functions under **30 lines** — extract helpers
- Use **protocols** for testability
- All classes/structs get **doc comments**

Check the [issues](https://github.com/markymark/WhisperKey/issues) for things to work on.

<!-- TODO: Update with actual repo URL -->

## Privacy

WhisperKey is built with privacy as a core principle:

- **All processing happens on-device** — transcription runs locally via whisper.cpp
- **No network calls** except the one-time model download from HuggingFace
- **No telemetry, analytics, or data collection** — zero tracking
- **No accounts, no cloud, no subscription** — it just works
- **Audio never leaves your Mac** — recordings are processed in memory and discarded

## License

[MIT](LICENSE)

## Acknowledgments

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov — the engine behind local transcription
- [HuggingFace](https://huggingface.co/) — model hosting
- [OpenAI Whisper](https://github.com/openai/whisper) — the original Whisper model
