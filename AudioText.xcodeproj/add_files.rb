#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'project.pbxproj'
project = Xcodeproj::Project.open('../AudioText.xcodeproj')

# Find the AudioText group and target
main_group = project.main_group
audiotext_group = main_group.find_subpath('AudioText')
components_group = audiotext_group.find_subpath('Components', true)

# Define the new files to add
new_files = [
  'NeumorphicStatusBanner.swift',
  'NeumorphicLanguageSelector.swift',
  'NeumorphicInputModeSelector.swift',
  'NeumorphicAudioVisualizer.swift',
  'NeumorphicRecordingButton.swift',
  'NeumorphicLibraryButton.swift'
]

# Add files to both iOS and macOS targets
ios_target = project.targets.find { |t| t.name == 'AudioText' }
macos_target = project.targets.find { |t| t.name == 'AudioText macOS' }

new_files.each do |filename|
  file_path = "Components/#{filename}"
  file_ref = components_group.new_file("../AudioText/#{file_path}")
  
  ios_target.add_file_references([file_ref]) if ios_target
  macos_target.add_file_references([file_ref]) if macos_target
end

project.save
puts "Successfully added #{new_files.count} files to the Xcode project"
