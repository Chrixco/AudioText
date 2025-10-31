# Add New Files to Xcode Project

## Files That Need to Be Added

The following files exist in your project directory but are NOT in the Xcode project yet:

### Main Files:
- ✅ `AudioText/MainTabView.swift` (NEW - iOS tab bar with Player tab)
- ✅ `AudioText/DesignSystem.swift` (NEW - Design system)
- ✅ `AudioText/HapticManager.swift` (NEW - Haptic feedback)
- ✅ `AudioText/WaveformTimeline.swift` (NEW - Waveform visualization)

### Component Files:
- ✅ `AudioText/Components/NeumorphicRotaryPlayButton.swift` (NEW - Large rotary play button)
- ✅ `AudioText/Components/NeumorphicPlaybackControls.swift` (NEW - Skip/speed controls)

## How to Add Them in Xcode

### Method 1: Using File → Add Files (Recommended)

1. **Open Xcode**:
   ```bash
   open AudioText.xcodeproj
   ```

2. **In Xcode, go to File → Add Files to "AudioText"...**

3. **Navigate to your project directory**: `/Users/chcorral/Documents/GITHUB/AudioText/`

4. **Select ALL these files** (hold ⌘ Cmd to select multiple):
   - `MainTabView.swift`
   - `DesignSystem.swift`
   - `HapticManager.swift`
   - `WaveformTimeline.swift`
   - Navigate into `Components/` folder and also select:
     - `NeumorphicRotaryPlayButton.swift`
     - `NeumorphicPlaybackControls.swift`

5. **IMPORTANT Settings in the dialog**:
   - ☐ **UNCHECK** "Copy items if needed" (files are already in the right place!)
   - ☑ **CHECK** "Create groups" (not folder references)
   - ☑ **CHECK** both targets:
     - ☑ AudioText
     - ☑ AudioText macOS

6. **Click "Add"**

7. **Build the project**: Press ⌘B or Product → Build

### Method 2: Using Drag & Drop

1. **Open Xcode**: `open AudioText.xcodeproj`

2. **Open Finder**: Navigate to `/Users/chcorral/Documents/GITHUB/AudioText/`

3. **Drag the main files** into the Xcode Project Navigator under the "AudioText" group:
   - `MainTabView.swift`
   - `DesignSystem.swift`
   - `HapticManager.swift`
   - `WaveformTimeline.swift`

4. **Drag the component files** into the "Components" group:
   - `NeumorphicRotaryPlayButton.swift`
   - `NeumorphicPlaybackControls.swift`

5. **In the dialog that appears**:
   - ☐ UNCHECK "Copy items if needed"
   - ☑ CHECK both "AudioText" and "AudioText macOS" targets
   - Click "Finish"

6. **Build**: Press ⌘B

## Expected Result

After adding the files and building, you should have:

✅ **Zero build errors** related to missing files
✅ **iOS app with 4 tabs**: Record, Library, Player, Settings
✅ **Player tab featuring**:
   - Large neumorphic rotary play button (220pt diameter)
   - Waveform timeline
   - Skip forward/backward controls
   - Playback speed selector
   - Collapsible equalizer

## Verify Files Were Added

After adding, you can verify by checking if these files appear in the Project Navigator (left sidebar in Xcode) under:
- `AudioText/` (main files)
- `AudioText/Components/` (component files)

## Quick Commands

```bash
# Open Xcode
open AudioText.xcodeproj

# List the files that need to be added
ls -1 AudioText/{MainTabView,DesignSystem,HapticManager,WaveformTimeline}.swift
ls -1 AudioText/Components/Neumorphic{RotaryPlayButton,PlaybackControls}.swift

# Build from command line (after adding files in Xcode)
xcodebuild -scheme AudioText -sdk iphonesimulator build
```

## Troubleshooting

If you still get "Cannot find 'MainTabView' in scope":
1. Make sure `MainTabView.swift` appears in the Project Navigator
2. Click on `MainTabView.swift` in the navigator
3. In the File Inspector (right sidebar), verify both targets are checked:
   - ☑ AudioText
   - ☑ AudioText macOS
4. Clean build folder: Shift+⌘+K
5. Rebuild: ⌘B
