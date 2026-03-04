# Seefi iOS – Makefile
# Run `make help` for available targets

PROJECT := Seefi
SCHEME := Seefi
CONFIGURATION ?= Debug

# Simulator for run target (override: make run SIMULATOR="iPhone 16")
SIMULATOR ?= iPhone 16

.PHONY: help generate build build-release build-device run clean open install-tools install-platform archive list-simulators

help:
	@echo "Seefi iOS – Build targets"
	@echo ""
	@echo "  make generate         Regenerate Xcode project from project.yml"
	@echo "  make build            Build for iOS Simulator (Debug)"
	@echo "  make build-release    Build for iOS Simulator (Release)"
	@echo "  make build-device     Build for generic iOS device (requires signing)"
	@echo "  make run              Build and run on simulator (default: $(SIMULATOR))"
	@echo "  make clean            Remove build artifacts and DerivedData"
	@echo "  make open             Open project in Xcode"
	@echo "  make install-tools    Install XcodeGen via Homebrew"
	@echo "  make install-platform Download iOS Simulator runtime (if build fails with 'iOS not installed')"
	@echo "  make archive          Create .xcarchive for distribution"
	@echo "  make list-simulators  List available iOS simulators"
	@echo ""
	@echo "Overrides:"
	@echo "  CONFIGURATION=Release  Use Release configuration"
	@echo "  SIMULATOR=\"iPhone 16\"  Use specific simulator for run"

generate:
	xcodegen generate

build: generate
	xcodebuild build \
		-project $(PROJECT).xcodeproj \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' \
		-configuration $(CONFIGURATION)

build-release: CONFIGURATION = Release
build-release: build

build-device: generate
	xcodebuild build \
		-project $(PROJECT).xcodeproj \
		-scheme $(SCHEME) \
		-destination 'generic/platform=iOS' \
		-configuration $(CONFIGURATION)

run: generate
	xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	xcodebuild build \
		-project $(PROJECT).xcodeproj \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,OS=18.6,name=$(SIMULATOR)' \
		-configuration $(CONFIGURATION) \
		-derivedDataPath build
	@xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/$(PROJECT).app
	@xcrun simctl launch booted com.seefi.Seefi

clean:
	rm -rf build/
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(PROJECT)-*
	@echo "Cleaned build artifacts and DerivedData"

open: generate
	open $(PROJECT).xcodeproj

install-tools:
	brew install xcodegen

install-platform:
	@echo "Downloading iOS Simulator runtime (required for make build)..."
	xcodebuild -downloadPlatform iOS

list-simulators:
	@xcrun simctl list devices available | grep -E "iPhone|iPad" || true

archive: generate
	@if [ -z "$$DEVELOPMENT_TEAM" ]; then \
		echo "Set DEVELOPMENT_TEAM for archive, e.g.: make archive DEVELOPMENT_TEAM=XXXXXXXXXX"; exit 1; \
	fi
	xcodebuild archive \
		-project $(PROJECT).xcodeproj \
		-scheme $(SCHEME) \
		-archivePath build/$(PROJECT).xcarchive \
		-destination 'generic/platform=iOS' \
		CODE_SIGN_STYLE=Manual \
		DEVELOPMENT_TEAM="$$DEVELOPMENT_TEAM"
	@echo "Archive created at build/$(PROJECT).xcarchive"
