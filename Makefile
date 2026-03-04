APP_NAME    = HealthKitExporter
PROJECT     = HealthKitExporter.xcodeproj
SCHEME      = HealthKitExporter
BUILD_DIR   = build
VERSION     = $(shell grep 'CFBundleShortVersionString' project.yml | sed 's/.*"\(.*\)".*/\1/')

DEVELOPMENT_TEAM ?=

APP_PATH    = $(BUILD_DIR)/$(APP_NAME).app
DMG_PATH    = $(BUILD_DIR)/$(APP_NAME)-v$(VERSION).dmg

DERIVED_DATA_APP = $(HOME)/Library/Developer/Xcode/DerivedData/$(APP_NAME)-*/Build/Products

.PHONY: generate build test lint release dmg clean

generate:
	xcodegen generate --spec project.yml

build: generate
	xcodebuild -scheme $(SCHEME) \
		-destination "generic/platform=macOS" \
		build CODE_SIGNING_ALLOWED=NO
	mkdir -p $(BUILD_DIR)
	cp -R $(DERIVED_DATA_APP)/Debug/$(APP_NAME).app $(BUILD_DIR)/

lint:
	swiftlint lint --strict

test: generate
	xcodebuild -scheme $(SCHEME) \
		-destination "platform=macOS,arch=arm64" \
		test CODE_SIGNING_ALLOWED=NO

release: generate
ifdef DEVELOPMENT_TEAM
	xcodebuild -scheme $(SCHEME) \
		-destination "generic/platform=macOS" \
		-configuration Release \
		DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) \
		ENABLE_HARDENED_RUNTIME=YES \
		build
else
	xcodebuild -scheme $(SCHEME) \
		-destination "generic/platform=macOS" \
		-configuration Release \
		CODE_SIGNING_ALLOWED=NO \
		build
endif
	mkdir -p $(BUILD_DIR)
	cp -R $(DERIVED_DATA_APP)/Release/$(APP_NAME).app $(BUILD_DIR)/

dmg: release
	rm -f "$(DMG_PATH)"
ifdef DEVELOPMENT_TEAM
	create-dmg \
		--volname "HealthKit Exporter" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon "$(APP_NAME).app" 150 200 \
		--app-drop-link 450 200 \
		--no-internet-enable \
		--codesign "Developer ID Application" \
		"$(DMG_PATH)" \
		"$(APP_PATH)"
else
	create-dmg \
		--volname "HealthKit Exporter" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon "$(APP_NAME).app" 150 200 \
		--app-drop-link 450 200 \
		--no-internet-enable \
		"$(DMG_PATH)" \
		"$(APP_PATH)"
endif

clean:
	rm -rf $(BUILD_DIR)
	xcodebuild -scheme $(SCHEME) clean
