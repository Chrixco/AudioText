#!/bin/bash

echo "🔧 Quick Fix for Xcode 'Cannot find type in scope' errors"
echo ""

# Verify files exist
echo "📁 Verifying backend files exist..."
FILES=(
    "AudioText/AudioRecorder.swift"
    "AudioText/AudioPlayer.swift"
    "AudioText/SpeechRecognizer.swift"
    "AudioText/OpenAIService.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MISSING!"
        exit 1
    fi
done

echo ""
echo "🎯 SOLUTION: Add these files to Xcode project"
echo ""
echo "📋 Step-by-Step Instructions:"
echo ""
echo "1. In Xcode Project Navigator (left sidebar):"
echo "   - Right-click on 'AudioText' folder (blue icon)"
echo "   - Select 'Add Files to AudioText'"
echo ""
echo "2. Select these 4 files:"
for file in "${FILES[@]}"; do
    echo "   - $file"
done
echo ""
echo "3. In the dialog that appears:"
echo "   ✅ Check 'AudioText' target"
echo "   ✅ Check 'AudioText macOS' target"
echo "   ✅ Check 'Copy items if needed'"
echo "   - Click 'Add'"
echo ""
echo "4. Clean and Build:"
echo "   - Clean Build Folder: Cmd+Shift+K"
echo "   - Build Project: Cmd+B"
echo ""
echo "✅ This will fix all 'Cannot find type in scope' errors!"
echo ""
echo "🚀 After adding files, your app will have:"
echo "   - Real audio recording with file saving"
echo "   - Audio playback with controls"
echo "   - Built-in speech recognition"
echo "   - OpenAI Whisper API integration"
echo "   - File management and settings"
