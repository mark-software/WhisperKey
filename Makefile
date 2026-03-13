PROJECT = WhisperKey.xcodeproj
SCHEME = WhisperKey
CONFIG = Release
BUILD_DIR = build
DERIVED_DATA = $(BUILD_DIR)/DerivedData
APP_PATH = $(DERIVED_DATA)/Build/Products/$(CONFIG)/WhisperKey.app
ZIP_PATH = $(BUILD_DIR)/WhisperKey.zip

.PHONY: build zip clean test-quarantine

build:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-destination 'platform=macOS,arch=arm64' \
		-derivedDataPath $(DERIVED_DATA) \
		ARCHS=arm64 \
		ONLY_ACTIVE_ARCH=NO \
		CODE_SIGN_IDENTITY="-" \
		ENABLE_HARDENED_RUNTIME=NO

zip: build
	ditto -c -k --keepParent "$(APP_PATH)" "$(ZIP_PATH)"
	@echo "Created $(ZIP_PATH)"

test-quarantine: zip
	rm -rf /tmp/WhisperKeyTest
	mkdir -p /tmp/WhisperKeyTest
	ditto -x -k "$(ZIP_PATH)" /tmp/WhisperKeyTest
	xattr -w com.apple.quarantine "0081;$(shell printf '%x' $$(date +%s));Safari;00000000-0000-0000-0000-000000000000" /tmp/WhisperKeyTest/WhisperKey.app
	@echo ""
	@echo "=== Quarantined app ready ==="
	@echo "To test mic permission from scratch:"
	@echo "  tccutil reset Microphone com.whisperkey.app"
	@echo "  open /tmp/WhisperKeyTest/WhisperKey.app"
	@echo ""
	@echo "Verify no hardened runtime:"
	@echo "  codesign -dvvv /tmp/WhisperKeyTest/WhisperKey.app"
	@echo ""

clean:
	rm -rf $(BUILD_DIR)
