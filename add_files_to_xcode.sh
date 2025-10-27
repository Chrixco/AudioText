#!/bin/bash

# Script to help add Swift files to Xcode project
echo "🔧 Adding Swift files to Xcode project..."

# Check if we're in the right directory
if [ ! -f "AudioText.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the AudioText project root directory"
    exit 1
fi

echo "📁 Current project structure:"
echo "AudioText/"
echo "├── AudioTextApp.swift ✅"
echo "├── ContentView.swift ✅"
echo "├── Design/"
echo "│   ├── NeumorphicColors.swift ⚠️  (needs to be added to Xcode)"
echo "│   └── NeumorphicButton.swift ⚠️  (needs to be added to Xcode)"
echo "├── ViewModels/"
echo "│   └── AudioTextViewModel.swift ⚠️  (needs to be added to Xcode)"
echo "├── Services/"
echo "│   ├── AudioRecorder.swift ⚠️  (needs to be added to Xcode)"
echo "│   └── WhisperService.swift ⚠️  (needs to be added to Xcode)"
echo "└── Models/"
echo "    └── TranscriptionResult.swift ⚠️  (needs to be added to Xcode)"

echo ""
echo "🎯 To fix the 'Cannot find AudioTextViewModel' error:"
echo ""
echo "1. Open AudioText.xcodeproj in Xcode"
echo "2. Right-click on 'AudioText' in the project navigator"
echo "3. Select 'New Group' and name it 'ViewModels'"
echo "4. Right-click on 'ViewModels' → 'Add Files to AudioText'"
echo "5. Navigate to and select: AudioText/ViewModels/AudioTextViewModel.swift"
echo "6. Make sure 'AudioText' target is checked"
echo "7. Click 'Add'"
echo ""
echo "8. Repeat for other groups:"
echo "   - Design group: NeumorphicColors.swift, NeumorphicButton.swift"
echo "   - Services group: AudioRecorder.swift, WhisperService.swift"
echo "   - Models group: TranscriptionResult.swift"
echo ""
echo "9. For each file, also check 'AudioText macOS' target in File Inspector"
echo ""
echo "10. Clean build folder: Cmd+Shift+K"
echo "11. Build: Cmd+B"
echo ""
echo "✅ This will resolve the scope error and make all classes available!"
