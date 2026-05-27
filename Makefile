APP_NAME=TouchBarCustomizer
BUILD_DIR=build
APP_BUNDLE=$(BUILD_DIR)/$(APP_NAME).app
MACOS_DIR=$(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR=$(APP_BUNDLE)/Contents/Resources

SWIFT_FILES=main.swift AppDelegate.swift TouchBarManager.swift Actions.swift
BRIDGING_HEADER=TouchBarPrivate.h

.PHONY: all build run clean

all: build

build:
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	swiftc -O -sdk $$(xcrun --show-sdk-path --sdk macosx) \
		-import-objc-header $(BRIDGING_HEADER) \
		-F /System/Library/PrivateFrameworks \
		-framework DFRFoundation \
		$(SWIFT_FILES) \
		-o $(MACOS_DIR)/$(APP_NAME)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@echo "Build successful: $(APP_BUNDLE)"

run: build
	open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)
