#!/bin/bash

# Add AudioVisualizer.swift to Xcode project properly
echo "Adding AudioVisualizer.swift to Xcode project..."

# Create a backup
cp AudioText.xcodeproj/project.pbxproj AudioText.xcodeproj/project.pbxproj.backup

# Add file reference after FilesView.swift
sed -i '' '/BB22222222222232 \/\* FilesView.swift \*\//a\
		BB22222222222233 /* AudioVisualizer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AudioVisualizer.swift; sourceTree = "<group>"; };
' AudioText.xcodeproj/project.pbxproj

# Add build file entries for iOS
sed -i '' '/AA11111111111114 \/\* FilesView.swift in Sources \*\//a\
		AA11111111111122 /* AudioVisualizer.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB22222222222233 /* AudioVisualizer.swift */; };
' AudioText.xcodeproj/project.pbxproj

# Add build file entries for macOS
sed -i '' '/AA11111111111121 \/\* FilesView.swift in Sources \*\//a\
		AA11111111111123 /* AudioVisualizer.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB22222222222233 /* AudioVisualizer.swift */; };
' AudioText.xcodeproj/project.pbxproj

# Add to the group after FilesView.swift
sed -i '' '/BB22222222222232 \/\* FilesView.swift \*\//a\
		BB22222222222233 /* AudioVisualizer.swift */,
' AudioText.xcodeproj/project.pbxproj

# Add to iOS sources build phase
sed -i '' '/AA11111111111114 \/\* FilesView.swift in Sources \*\//a\
				AA11111111111122 /* AudioVisualizer.swift in Sources */,
' AudioText.xcodeproj/project.pbxproj

# Add to macOS sources build phase  
sed -i '' '/AA11111111111121 \/\* FilesView.swift in Sources \*\//a\
				AA11111111111123 /* AudioVisualizer.swift in Sources */,
' AudioText.xcodeproj/project.pbxproj

echo "✅ AudioVisualizer.swift added to Xcode project!"
echo "📱 You can now build and run the app with the audio visualizer!"
