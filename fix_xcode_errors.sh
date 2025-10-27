#!/bin/bash

echo "🔧 Fixing Xcode 'Cannot find type in scope' errors..."

# Check if files exist
FILES=(
    "AudioText/AudioRecorder.swift"
    "AudioText/AudioPlayer.swift"
    "AudioText/SpeechRecognizer.swift"
    "AudioText/OpenAIService.swift"
)

echo "📁 Checking backend files..."
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

echo ""
echo "🎯 The issue is that the backend files aren't added to Xcode project yet."
echo ""
echo "📋 Manual Steps to Fix:"
echo "1. In Xcode, right-click on 'AudioText' folder"
echo "2. Select 'Add Files to AudioText'"
echo "3. Select these files:"
for file in "${FILES[@]}"; do
    echo "   - $file"
done
echo "4. Make sure both targets are checked:"
echo "   ✅ AudioText"
echo "   ✅ AudioText macOS"
echo "5. Click 'Add'"
echo "6. Clean build folder: Cmd+Shift+K"
echo "7. Build: Cmd+B"
echo ""
echo "✅ This will resolve all 'Cannot find type in scope' errors!"

# Also check the current project structure
echo ""
echo "📁 Current project structure:"
ls -la AudioText/
