#!/bin/bash

# Add AudioVisualizer.swift to Xcode project
echo "Adding AudioVisualizer.swift to Xcode project..."

# Create a backup of the project file
cp AudioText.xcodeproj/project.pbxproj AudioText.xcodeproj/project.pbxproj.backup

# Add the new file reference
sed -i '' '/BB22222222222232 \/\* FilesView.swift \*\//a\
		BB22222222222233 /* AudioVisualizer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AudioVisualizer.swift; sourceTree = "<group>"; };
' AudioText.xcodeproj/project.pbxproj

# Add the build file entries
sed -i '' '/AA11111111111114 \/\* FilesView.swift in Sources \*\//a\
		AA11111111111122 /* AudioVisualizer.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB22222222222233 /* AudioVisualizer.swift */; };
' AudioText.xcodeproj/project.pbxproj

sed -i '' '/AA11111111111121 \/\* FilesView.swift in Sources \*\//a\
		AA11111111111123 /* AudioVisualizer.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB22222222222233 /* AudioVisualizer.swift */; };
' AudioText.xcodeproj/project.pbxproj

# Add to the group
sed -i '' '/BB22222222222232 \/\* FilesView.swift \*\//a\
		BB22222222222233 /* AudioVisualizer.swift */,
' AudioText.xcodeproj/project.pbxproj

# Add to iOS sources
sed -i '' '/AA11111111111114 \/\* FilesView.swift in Sources \*\//a\
				AA11111111111122 /* AudioVisualizer.swift in Sources */,
' AudioText.xcodeproj/project.pbxproj

# Add to macOS sources
sed -i '' '/AA11111111111121 \/\* FilesView.swift in Sources \*\//a\
				AA11111111111123 /* AudioVisualizer.swift in Sources */,
' AudioText.xcodeproj/project.pbxproj

echo "✅ AudioVisualizer.swift added to Xcode project!"
echo "📱 You can now build and run the app with the audio visualizer!"
