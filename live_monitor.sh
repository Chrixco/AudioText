#!/bin/bash

echo "🔧 Live AudioText Project Monitor"
echo "================================="
echo ""

# Function to monitor project status
monitor_project() {
    echo "📊 Project Status Check:"
    echo "----------------------"
    
    # Check backend files
    echo "📁 Backend Files:"
    for file in AudioRecorder.swift AudioPlayer.swift SpeechRecognizer.swift OpenAIService.swift; do
        if [ -f "AudioText/$file" ]; then
            if grep -q "$file" AudioText.xcodeproj/project.pbxproj 2>/dev/null; then
                echo "✅ $file - In project"
            else
                echo "❌ $file - NOT in project"
            fi
        else
            echo "❌ $file - MISSING"
        fi
    done
    
    echo ""
    echo "🔍 Xcode Build Status:"
    echo "---------------------"
    
    # Check for common build errors
    if grep -q "Cannot find type" AudioText.xcodeproj/project.pbxproj 2>/dev/null; then
        echo "❌ Build errors detected"
    else
        echo "✅ No obvious build errors in project file"
    fi
    
    echo ""
    echo "🚀 Next Steps:"
    echo "-------------"
    echo "1. Add backend files to Xcode project"
    echo "2. Clean build folder (Cmd+Shift+K)"
    echo "3. Build project (Cmd+B)"
    echo "4. Check for remaining errors"
}

# Run the monitor
monitor_project

echo ""
echo "🔄 To run this monitor again:"
echo "   ./live_monitor.sh"
echo ""
echo "📱 To add files to Xcode:"
echo "   1. Right-click AudioText folder in Xcode"
echo "   2. Select 'Add Files to AudioText'"
echo "   3. Select the 4 backend files"
echo "   4. Check both targets and click Add"
