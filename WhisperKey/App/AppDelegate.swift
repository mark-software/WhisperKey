import AppKit
import AVFoundation

/// Main application delegate handling lifecycle and wiring all components together
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarManager: MenuBarManager?
    private let audioRecorder = AudioRecorder()
    private let transcriber = WhisperTranscriber()
    private let textOutputManager = TextOutputManager()
    private let modelDownloader = ModelDownloader()
    private var recordingIndicator: RecordingIndicatorWindow?
    private var isProcessing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPermissions()
        setupMenuBar()
        setupHotkey()
        loadModel()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
        transcriber.unloadModel()
    }

    // MARK: - Setup

    private func setupPermissions() {
        let permManager = PermissionManager.shared

        if !permManager.microphoneGranted {
            permManager.requestMicrophoneAccess { granted in
                if !granted {
                    print("AppDelegate: Microphone access denied")
                }
            }
        }

        if !permManager.accessibilityGranted {
            permManager.requestAccessibilityAccess()
        }
    }

    private func setupMenuBar() {
        menuBarManager = MenuBarManager(modelDownloader: modelDownloader)
        menuBarManager?.setupMenuBar()

        recordingIndicator = RecordingIndicatorWindow()
    }

    private func setupHotkey() {
        let hotkeyManager = HotkeyManager.shared

        hotkeyManager.onHotkeyDown = { [weak self] in
            self?.startRecording()
        }

        hotkeyManager.onHotkeyUp = { [weak self] in
            self?.stopRecordingAndTranscribe()
        }

        hotkeyManager.start()
    }

    private func loadModel() {
        let settings = AppSettings.shared
        guard let model = ModelDownloader.WhisperModel(rawValue: settings.selectedModel) else { return }

        if modelDownloader.isModelDownloaded(model) {
            loadModelFile(model)
        } else {
            modelDownloader.downloadModel(model) { [weak self] result in
                switch result {
                case .success:
                    self?.loadModelFile(model)
                case .failure(let error):
                    print("AppDelegate: Failed to download model: \(error)")
                }
            }
        }
    }

    private func loadModelFile(_ model: ModelDownloader.WhisperModel) {
        let path = modelDownloader.modelPath(model)
        do {
            try transcriber.loadModel(at: path)
            print("AppDelegate: Model loaded successfully")
        } catch {
            print("AppDelegate: Failed to load model: \(error)")
        }
    }

    // MARK: - Recording Pipeline

    private func startRecording() {
        guard !isProcessing else { return }

        do {
            try audioRecorder.startRecording()
            menuBarManager?.setRecording(true)
            recordingIndicator?.showIndicator()

            if AppSettings.shared.playSoundsEnabled {
                NSSound.tink?.play()
            }
        } catch {
            print("AppDelegate: Failed to start recording: \(error)")
        }
    }

    private func stopRecordingAndTranscribe() {
        let samples = audioRecorder.stopRecording()
        menuBarManager?.setRecording(false)
        recordingIndicator?.hideIndicator()

        if AppSettings.shared.playSoundsEnabled {
            NSSound.pop?.play()
        }

        guard !samples.isEmpty else {
            print("AppDelegate: No audio samples captured")
            return
        }

        guard transcriber.isModelLoaded else {
            print("AppDelegate: Model not loaded, cannot transcribe")
            return
        }

        isProcessing = true

        Task {
            do {
                let text = try await transcriber.transcribe(samples: samples)

                await MainActor.run {
                    guard !text.isEmpty else {
                        print("AppDelegate: Transcription returned empty text")
                        isProcessing = false
                        return
                    }

                    let settings = AppSettings.shared
                    textOutputManager.output(
                        text: text,
                        autoPaste: settings.autoPasteEnabled
                    )

                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    print("AppDelegate: Transcription failed: \(error)")
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - System Sound Helpers

extension NSSound {
    static let tink = NSSound(named: "Tink")
    static let pop = NSSound(named: "Pop")
}
