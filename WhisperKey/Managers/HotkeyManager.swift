import Foundation
import AppKit
import CoreGraphics

/// Manages global hotkey detection via CGEvent tap
final class HotkeyManager {
    static let shared = HotkeyManager()

    /// Called when the hotkey is pressed down
    var onHotkeyDown: (() -> Void)?

    /// Called when the hotkey is released
    var onHotkeyUp: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapThread: Thread?
    private var isHotkeyPressed = false

    private init() {}

    /// Start listening for the global hotkey
    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: hotkeyEventCallback,
            userInfo: refcon
        ) else {
            print("HotkeyManager: Failed to create event tap. Accessibility permission required.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        let thread = Thread { [weak self] in
            guard let self = self, let source = self.runLoopSource else { return }
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "com.whisperkey.hotkey"
        thread.qualityOfService = .userInteractive
        thread.start()
        tapThread = thread
    }

    /// Stop listening for the global hotkey
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopSourceInvalidate(source)
        }
        eventTap = nil
        runLoopSource = nil
        tapThread?.cancel()
        tapThread = nil
        isHotkeyPressed = false
    }

    /// Handle a CGEvent and determine if it matches the hotkey
    fileprivate func handleEvent(_ proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let binding = AppSettings.shared.hotkeyBinding

        if binding.isModifierOnly {
            return handleModifierOnlyHotkey(type: type, event: event, binding: binding)
        } else {
            return handleRegularHotkey(type: type, event: event, binding: binding)
        }
    }

    private func handleModifierOnlyHotkey(type: CGEventType, event: CGEvent, binding: HotkeyBinding) -> Unmanaged<CGEvent>? {
        guard type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let expectedFlags = CGEventFlags(rawValue: UInt64(binding.modifierFlags))

        if keyCode == binding.keyCode {
            if flags.contains(expectedFlags) && !isHotkeyPressed {
                isHotkeyPressed = true
                DispatchQueue.main.async { [weak self] in
                    self?.onHotkeyDown?()
                }
            } else if !flags.contains(expectedFlags) && isHotkeyPressed {
                isHotkeyPressed = false
                DispatchQueue.main.async { [weak self] in
                    self?.onHotkeyUp?()
                }
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleRegularHotkey(type: CGEventType, event: CGEvent, binding: HotkeyBinding) -> Unmanaged<CGEvent>? {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        guard keyCode == binding.keyCode else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        let requiredFlags = CGEventFlags(rawValue: UInt64(binding.modifierFlags))
        let hasRequiredModifiers = binding.modifierFlags == 0 || flags.contains(requiredFlags)

        if type == .keyDown && hasRequiredModifiers && !isHotkeyPressed {
            isHotkeyPressed = true
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyDown?()
            }
            return nil // consume the event
        } else if type == .keyUp && keyCode == binding.keyCode && isHotkeyPressed {
            isHotkeyPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyUp?()
            }
            return nil // consume the event
        }

        return Unmanaged.passUnretained(event)
    }
}

/// CGEvent tap callback function
private func hotkeyEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
    return manager.handleEvent(proxy, type: type, event: event)
}
