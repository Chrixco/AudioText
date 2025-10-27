#!/bin/bash

# AudioText Project Validation Script
echo "🔍 Validating AudioText Project Structure..."

# Check if project file exists
if [ ! -f "AudioText.xcodeproj/project.pbxproj" ]; then
    echo "❌ Project file not found!"
    exit 1
fi

# Check if workspace file exists
if [ ! -f "AudioText.xcodeproj/project.xcworkspace/contents.xcworkspacedata" ]; then
    echo "❌ Workspace file not found!"
    exit 1
fi

# Check if main app files exist
if [ ! -f "AudioText/AudioTextApp.swift" ]; then
    echo "❌ AudioTextApp.swift not found!"
    exit 1
fi

if [ ! -f "AudioText/ContentView.swift" ]; then
    echo "❌ ContentView.swift not found!"
    exit 1
fi

# Check if assets exist
if [ ! -d "AudioText/Assets.xcassets" ]; then
    echo "❌ Assets.xcassets not found!"
    exit 1
fi

# Check if macOS files exist
if [ ! -f "AudioText macOS/AudioTextApp.swift" ]; then
    echo "❌ macOS AudioTextApp.swift not found!"
    exit 1
fi

if [ ! -f "AudioText macOS/ContentView.swift" ]; then
    echo "❌ macOS ContentView.swift not found!"
    exit 1
fi

# Check if additional Swift files exist
echo "📁 Checking additional Swift files..."

if [ -f "AudioText/Design/NeumorphicColors.swift" ]; then
    echo "✅ NeumorphicColors.swift found"
else
    echo "⚠️  NeumorphicColors.swift not found (will need to be added)"
fi

if [ -f "AudioText/Design/NeumorphicButton.swift" ]; then
    echo "✅ NeumorphicButton.swift found"
else
    echo "⚠️  NeumorphicButton.swift not found (will need to be added)"
fi

if [ -f "AudioText/ViewModels/AudioTextViewModel.swift" ]; then
    echo "✅ AudioTextViewModel.swift found"
else
    echo "⚠️  AudioTextViewModel.swift not found (will need to be added)"
fi

if [ -f "AudioText/Services/AudioRecorder.swift" ]; then
    echo "✅ AudioRecorder.swift found"
else
    echo "⚠️  AudioRecorder.swift not found (will need to be added)"
fi

if [ -f "AudioText/Services/WhisperService.swift" ]; then
    echo "✅ WhisperService.swift found"
else
    echo "⚠️  WhisperService.swift not found (will need to be added)"
fi

if [ -f "AudioText/Models/TranscriptionResult.swift" ]; then
    echo "✅ TranscriptionResult.swift found"
else
    echo "⚠️  TranscriptionResult.swift not found (will need to be added)"
fi

echo ""
echo "🎉 Project structure validation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open AudioText.xcodeproj in Xcode"
echo "2. Follow ADD_FILES.md to add remaining Swift files"
echo "3. Set your OpenAI API key"
echo "4. Build and test the app"
echo ""
echo "🚀 Ready for development!"
