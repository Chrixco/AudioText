#!/bin/bash

# AudioText Build Script
# This script helps build and test the AudioText project

set -e

echo "🎵 AudioText Build Script"
echo "========================="

# Check if we're in the right directory
if [ ! -f "AudioText.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the AudioText project root directory"
    exit 1
fi

# Function to build for iOS
build_ios() {
    echo "📱 Building for iOS..."
    xcodebuild -project AudioText.xcodeproj \
               -scheme AudioText \
               -destination 'platform=iOS Simulator,name=iPhone 15' \
               -configuration Debug \
               build
    echo "✅ iOS build completed"
}

# Function to build for macOS
build_macos() {
    echo "💻 Building for macOS..."
    xcodebuild -project AudioText.xcodeproj \
               -scheme "AudioText macOS" \
               -destination 'platform=macOS' \
               -configuration Debug \
               build
    echo "✅ macOS build completed"
}

# Function to run tests
run_tests() {
    echo "🧪 Running tests..."
    xcodebuild test -project AudioText.xcodeproj \
                   -scheme AudioText \
                   -destination 'platform=iOS Simulator,name=iPhone 15' \
                   -only-testing:AudioTextTests
    echo "✅ Tests completed"
}

# Function to clean build
clean_build() {
    echo "🧹 Cleaning build folder..."
    xcodebuild clean -project AudioText.xcodeproj -scheme AudioText
    echo "✅ Clean completed"
}

# Parse command line arguments
case "${1:-help}" in
    "ios")
        build_ios
        ;;
    "macos")
        build_macos
        ;;
    "test")
        run_tests
        ;;
    "clean")
        clean_build
        ;;
    "all")
        clean_build
        build_ios
        build_macos
        run_tests
        ;;
    "help"|*)
        echo "Usage: $0 [ios|macos|test|clean|all]"
        echo ""
        echo "Commands:"
        echo "  ios     - Build for iOS"
        echo "  macos   - Build for macOS"
        echo "  test    - Run unit tests"
        echo "  clean   - Clean build folder"
        echo "  all     - Clean, build all targets, and run tests"
        echo "  help    - Show this help message"
        ;;
esac

echo "🎉 Done!"
