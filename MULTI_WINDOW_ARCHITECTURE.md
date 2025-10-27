# Multi-Window Architecture Implementation

## Overview

AudioText now uses a proper multi-window architecture where each major section (Recording, Library, Settings, Transcription) opens in its own dedicated window instead of using floating sheets/modals.

## Architecture Changes

### Before
- Single window with modal sheets for Settings, Library, and Transcription
- iOS-style interface on macOS

### After
- **macOS**: Separate dedicated windows for each section
- **iOS**: Continues to use sheets (iOS doesn't support multi-window the same way)
- Proper window management with `Window` and `WindowGroup` scenes

## Window Structure

### 1. Main Recording Window (`WindowGroup` - "main")
- Primary interface for audio recording
- Always visible on launch
- Contains the recording controls and visualizer

### 2. Settings Window (`Window` - "settings")
- Dedicated window for app settings
- Transcription method selection
- API key configuration
- Language and text style options
- **Size**: 600x700

### 3. Library/Files Window (`Window` - "files")
- Complete file management interface
- Recording list with playback controls
- Equalizer settings
- File operations (rename, share, delete)
- **Size**: 800x600

### 4. Transcription Window (`WindowGroup` - "transcription")
- Displays transcription results
- Can open multiple instances for different transcriptions
- Scrollable text view
- **Size**: 600x500

## Platform Differences

### macOS
- Uses `openWindow(id:)` to open new windows
- Each section in a separate, resizable window
- Native macOS multi-window experience
- Windows can be managed independently

### iOS
- Uses `.sheet()` modifiers for modal presentation
- Single window with sheet overlays
- Native iOS modal experience
- Falls back to traditional sheet presentation

## Implementation Details

### App Structure

**AudioTextApp.swift** (both iOS and macOS):
```swift
@main
struct AudioTextApp: App {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var openAIService = OpenAIService()

    var body: some Scene {
        // Main window
        WindowGroup(id: "main") { ... }

        // Settings window
        Window("Settings", id: "settings") { ... }

        // Files window
        Window("Library", id: "files") { ... }

        // Transcription window
        WindowGroup(id: "transcription", for: String.self) { ... }
    }
}
```

### Window Opening

**macOS**:
```swift
@Environment(\.openWindow) private var openWindow

// Open settings
openWindow(id: "settings")

// Open library
openWindow(id: "files")

// Open transcription with data
openWindow(id: "transcription", value: transcriptionText)
```

**iOS**:
```swift
@State private var showingSettings = false

// Show settings
.sheet(isPresented: $showingSettings) {
    SettingsView(...)
}
```

## New Files Created

1. **SettingsWindowView.swift** - Wrapper view for Settings window
2. **TranscriptionWindowView.swift** - Wrapper view for Transcription window

## Setup Instructions

### Adding Files to Xcode Project

The new Swift files need to be added to your Xcode project:

1. **Open Xcode** project (`AudioText.xcodeproj`)
2. **Right-click** on the "AudioText" folder (blue icon)
3. Select **"Add Files to AudioText..."**
4. Navigate to the AudioText folder
5. **Select these files**:
   - `SettingsWindowView.swift`
   - `TranscriptionWindowView.swift`
6. **Ensure** the following are checked:
   - ✅ "AudioText" target (iOS)
   - ✅ "AudioText macOS" target (macOS)
   - ✅ "Copy items if needed"
7. Click **"Add"**
8. **Clean** build folder: `Cmd+Shift+K`
9. **Build** project: `Cmd+B`

## Benefits

### User Experience
- ✅ Native macOS window management
- ✅ Each section in its own dedicated space
- ✅ Can view multiple windows side-by-side
- ✅ Better multitasking support
- ✅ More professional desktop app feel

### Development
- ✅ Cleaner separation of concerns
- ✅ Each window can be developed independently
- ✅ Better state management
- ✅ Platform-appropriate UI paradigms

## Usage

### Opening Windows

From the main recording window:

1. **Library Button** (bottom of screen) - Opens Library window
2. **Menu (⋯) → Library** - Opens Library window
3. **Menu (⋯) → Settings** - Opens Settings window
4. **Menu (⋯) → Transcription** - Opens Transcription window (when available)

### Window Management

- **macOS**: Use standard window controls (minimize, maximize, close)
- **Multiple instances**: Transcription windows support multiple instances
- **Persistent state**: Window positions are remembered by the system

## Testing

### Manual Testing Checklist

- [ ] Main window opens on launch
- [ ] Settings window opens from menu
- [ ] Library window opens from button and menu
- [ ] Transcription window opens after recording
- [ ] Multiple transcription windows can be opened
- [ ] All windows share the same data (via environment objects)
- [ ] iOS still uses sheets correctly
- [ ] Windows can be closed and reopened

### Build Verification

```bash
# iOS build
xcodebuild -project AudioText.xcodeproj -scheme AudioText \\
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# macOS build
xcodebuild -project AudioText.xcodeproj -scheme "AudioText macOS" \\
  -destination 'platform=macOS' build
```

## Troubleshooting

### Build Errors

**Error**: `Cannot find 'SettingsWindowView' in scope`
**Solution**: Make sure new Swift files are added to Xcode project (see Setup Instructions)

**Error**: `Cannot find 'openWindow' in scope`
**Solution**: Ensure you're building for macOS. iOS uses sheets instead.

### Runtime Issues

**Issue**: Windows don't open on macOS
**Solution**: Check that window IDs match between `openWindow(id:)` calls and Scene definitions

**Issue**: Shared data not updating
**Solution**: Verify environment objects are properly passed to all windows

## Future Enhancements

- [ ] Window position and size persistence
- [ ] Custom window toolbar
- [ ] Window-specific commands
- [ ] Keyboard shortcuts for window management
- [ ] Window tiling support
- [ ] Picture-in-picture mode for visualizer

## References

- [SwiftUI Window Management](https://developer.apple.com/documentation/swiftui/window)
- [WindowGroup Documentation](https://developer.apple.com/documentation/swiftui/windowgroup)
- [openWindow Environment Action](https://developer.apple.com/documentation/swiftui/environmentvalues/openwindow)
