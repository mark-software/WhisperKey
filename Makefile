PROJECT = WhisperKey.xcodeproj
SCHEME = WhisperKey
CONFIG = Release
BUILD_DIR = build
DERIVED_DATA = $(BUILD_DIR)/DerivedData
APP_PATH = $(DERIVED_DATA)/Build/Products/$(CONFIG)/WhisperKey.app
ZIP_PATH = $(BUILD_DIR)/WhisperKey.zip

.PHONY: build zip clean

build:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-destination 'platform=macOS,arch=arm64' \
		-derivedDataPath $(DERIVED_DATA) \
		ARCHS=arm64 \
		ONLY_ACTIVE_ARCH=NO \
		CODE_SIGN_IDENTITY="-"

zip: build
	ditto -c -k --keepParent "$(APP_PATH)" "$(ZIP_PATH)"
	@echo "Created $(ZIP_PATH)"

clean:
	rm -rf $(BUILD_DIR)
