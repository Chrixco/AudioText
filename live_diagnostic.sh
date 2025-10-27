#!/bin/bash

echo "🔧 Live AudioText Project Diagnostic Tool"
echo "========================================"
echo ""

# Function to check file status
check_file() {
    local file=$1
    if [ -f "$file" ]; then
        echo "✅ $file - EXISTS"
        # Check if file is in Xcode project (basic check)
        if grep -q "$(basename "$file")" AudioText.xcodeproj/project.pbxproj 2>/dev/null; then
            echo "   📱 Added to Xcode project"
        else
            echo "   ❌ NOT added to Xcode project"
        fi
    else
        echo "❌ $file - MISSING"
    fi
}

# Check backend files
echo "📁 Backend Files Status:"
echo "------------------------"
check_file "AudioText/AudioRecorder.swift"
check_file "AudioText/AudioPlayer.swift"
check_file "AudioText/SpeechRecognizer.swift"
check_file "AudioText/OpenAIService.swift"

echo ""
echo "📱 Xcode Project Status:"
echo "------------------------"
if [ -f "AudioText.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project exists"
    
    # Check if backend files are in project
    echo ""
    echo "🔍 Backend files in project:"
    for file in AudioRecorder.swift AudioPlayer.swift SpeechRecognizer.swift OpenAIService.swift; do
        if grep -q "$file" AudioText.xcodeproj/project.pbxproj; then
            echo "✅ $file - In project"
        else
            echo "❌ $file - NOT in project"
        fi
    done
else
    echo "❌ Xcode project missing"
fi

echo ""
echo "🚀 Quick Fix Commands:"
echo "---------------------"
echo "1. Add files to Xcode:"
echo "   - Right-click AudioText folder in Xcode"
echo "   - Select 'Add Files to AudioText'"
echo "   - Select the 4 backend files"
echo "   - Check both targets and click Add"
echo ""
echo "2. Clean and build:"
echo "   - Cmd+Shift+K (Clean)"
echo "   - Cmd+B (Build)"
echo ""
echo "3. Check for errors:"
echo "   - Look at Xcode Issues navigator"
echo "   - Check console for runtime errors"
