import Foundation
@testable import WhisperKey

/// Mock text output manager for testing
final class MockTextOutputManager: TextOutputting {
    var lastCopiedText: String?
    var pasteCallCount = 0
    var outputCallCount = 0
    var lastAutoPasteValue: Bool?

    func copyToClipboard(_ text: String) {
        lastCopiedText = text
    }

    func pasteFromClipboard() {
        pasteCallCount += 1
    }

    func output(text: String, autoPaste: Bool) {
        outputCallCount += 1
        lastCopiedText = text
        lastAutoPasteValue = autoPaste
    }
}
