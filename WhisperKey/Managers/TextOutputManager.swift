import Foundation
import AppKit
import CoreGraphics

/// Handles copying text to clipboard and simulating paste via Cmd+V
final class TextOutputManager: TextOutputting {

    /// Copy text to the system clipboard
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Paste clipboard contents into the active text field via simulated Cmd+V
    func pasteFromClipboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let source = CGEventSource(stateID: .hidSystemState)

            let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            keyDownEvent?.flags = .maskCommand

            let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyUpEvent?.flags = .maskCommand

            keyDownEvent?.post(tap: .cghidEventTap)
            keyUpEvent?.post(tap: .cghidEventTap)
        }
    }

    /// Copy text and optionally paste it into the active field
    func output(text: String, autoPaste: Bool) {
        copyToClipboard(text)

        if autoPaste {
            pasteFromClipboard()
        }
    }
}
