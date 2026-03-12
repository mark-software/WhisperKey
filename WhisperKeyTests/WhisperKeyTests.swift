import XCTest
@testable import WhisperKey

final class HotkeyBindingTests: XCTestCase {
    func testDefaultBinding() {
        let binding = HotkeyBinding.defaultBinding
        XCTAssertEqual(binding.keyCode, 61)
        XCTAssertTrue(binding.isModifierOnly)
        XCTAssertEqual(binding.displayString, "Right ⌥")
    }

    func testEquality() {
        let a = HotkeyBinding(keyCode: 61, modifierFlags: 0, isModifierOnly: true)
        let b = HotkeyBinding(keyCode: 61, modifierFlags: 0, isModifierOnly: true)
        XCTAssertEqual(a, b)
    }

    func testCodable() throws {
        let original = HotkeyBinding.defaultBinding
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HotkeyBinding.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDisplayStringWithModifiers() {
        let binding = HotkeyBinding(
            keyCode: 0, // A key
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            isModifierOnly: false
        )
        XCTAssertEqual(binding.displayString, "⌘A")
    }

    func testModifierOnlyDisplayStrings() {
        let cases: [(UInt16, String)] = [
            (61, "Right ⌥"),
            (58, "Left ⌥"),
            (62, "Right ⌃"),
            (59, "Left ⌃"),
            (60, "Right ⇧"),
            (56, "Left ⇧"),
            (55, "Left ⌘"),
            (54, "Right ⌘"),
        ]
        for (keyCode, expected) in cases {
            let binding = HotkeyBinding(keyCode: keyCode, modifierFlags: 0, isModifierOnly: true)
            XCTAssertEqual(binding.displayString, expected, "Failed for keyCode \(keyCode)")
        }
    }
}
