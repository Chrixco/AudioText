# Separate Windows Update - Library and Player

## Overview

The app now has **completely separate windows** for Library and Player, instead of them being tabs within a single Files window.

## New Window Structure

### macOS Windows (4 separate windows)

1. **Main Recording Window** - Audio recording interface
2. **Library Window** (NEW) - List of all recordings with playback controls
3. **Player Window** (NEW) - Equalizer and playback controls for selected recording
4. **Settings Window** - App configuration
5. **Transcription Window** - View transcription results

### iOS (Sheets)

On iOS, these still appear as modal sheets:
- Library sheet (with tab picker for Library/Player views)
- Settings sheet
- Transcription sheet

## New Files Created

1. **LibraryWindowView.swift** - Dedicated Library window
   - Shows list of all recordings
   - Play/pause controls for each recording
   - Context menu: Rename, Share, Delete
   - Empty state when no recordings

2. **PlayerWindowView.swift** - Dedicated Player/Equalizer window
   - Recording selector dropdown
   - Full equalizer controls
   - Playback controls
   - Transcript viewing
   - Empty state when no recordings

## Window Sizes

- **Library Window**: 700×600
- **Player Window**: 800×700
- **Settings Window**: 600×700
- **Transcription Window**: 600×500

## How to Access Windows (macOS)

### From Main Window:

**Library Button** (bottom of screen)
- Opens **Library Window**

**Menu (⋯) Options:**
- **Library** → Opens Library Window
- **Player** → Opens Player Window
- **Settings** → Opens Settings Window
- **Transcription** → Opens Transcription Window (when available)

## Usage Examples

### Typical Workflow:

1. **Main Window**: Record audio
2. **Library Window**: Browse all recordings, quick playback
3. **Player Window**: Fine-tune equalizer settings for a specific recording
4. **Transcription Window**: View/copy transcription results

### Multi-Window Benefits:

- View Library and Player side-by-side
- Adjust equalizer while browsing other recordings
- Independent window positioning and sizing
- Better screen real estate usage
- More productive workflow

## Technical Implementation

### App Structure

**AudioTextApp.swift** (both iOS & macOS):
```swift
// Main window
WindowGroup(id: "main") { ContentView() }

// Library window (NEW)
WindowGroup(id: "library") { LibraryWindowView() }

// Player window (NEW)
WindowGroup(id: "player") { PlayerWindowView() }

// Settings window
WindowGroup(id: "settings") { SettingsWindowView() }

// Transcription window
WindowGroup(id: "transcription", for: String.self) { ... }
```

### Opening Windows (macOS)

```swift
@Environment(\.openWindow) private var openWindow

// Open library
openWindow(id: "library")

// Open player
openWindow(id: "player")
```

### iOS Behavior (unchanged)

iOS continues to use sheets with the existing FilesView that has tabs for Library and Player.

## Features per Window

### Library Window
- ✅ Scrollable list of recordings
- ✅ Play/pause button per recording
- ✅ File name and duration display
- ✅ Equalizer indicator (shows if custom settings exist)
- ✅ Context menu (Rename, Share, Delete)
- ✅ Empty state with helpful message
- ✅ Recording count in toolbar

### Player Window
- ✅ Recording selector dropdown
- ✅ Full equalizer with 10 frequency bands
- ✅ Playback controls (play/pause, progress)
- ✅ Waveform visualization
- ✅ Transcript viewing
- ✅ Save equalizer settings
- ✅ Empty state when no recordings

## Setup Instructions

### Adding Files to Xcode

1. **Open Xcode** (should already be open)
2. **Right-click** on "AudioText" folder in Project Navigator
3. Select **"Add Files to AudioText..."**
4. Navigate to AudioText folder
5. **Select these files:**
   - LibraryWindowView.swift
   - PlayerWindowView.swift
6. **Ensure checked:**
   - ✅ AudioText (iOS target)
   - ✅ AudioText macOS (macOS target)
7. Click **"Add"**
8. **Clean**: `Cmd+Shift+K`
9. **Build**: `Cmd+B`

## Testing Checklist

### macOS

- [ ] Main window opens on launch
- [ ] Library button opens Library window
- [ ] Menu → Library opens Library window
- [ ] Menu → Player opens Player window
- [ ] Can open multiple windows simultaneously
- [ ] Windows are independent (can be moved separately)
- [ ] Data syncs across windows (environment objects)
- [ ] Playback controls work in both Library and Player windows
- [ ] Equalizer changes save and persist

### iOS

- [ ] Library button opens sheet with tabs
- [ ] Can switch between Library and Player tabs
- [ ] All functionality works in sheet mode

## Comparison: Before vs After

### Before
- Single "Files" window with internal tabs
- Had to switch tabs to see different views
- Limited multi-tasking

### After
- **Library Window**: Quick browsing and playback
- **Player Window**: Detailed controls and equalization
- Can view both simultaneously
- Better workflow for audio editing

## Benefits

### User Experience
- ✅ Native macOS multi-window experience
- ✅ Side-by-side Library and Player viewing
- ✅ Independent window management
- ✅ More screen space utilization
- ✅ Professional desktop app feel

### Development
- ✅ Clean separation of concerns
- ✅ Easier to maintain individual windows
- ✅ Better code organization
- ✅ Platform-appropriate UI patterns

## Future Enhancements

- [ ] Keyboard shortcuts for window management
- [ ] Window menu with "Show Library", "Show Player" commands
- [ ] Drag-and-drop between Library and Player
- [ ] Mini player mode
- [ ] Picture-in-picture visualizer

## Troubleshooting

### Build Errors

**Error**: `Cannot find 'LibraryWindowView' in scope`
**Solution**: Add LibraryWindowView.swift and PlayerWindowView.swift to Xcode project

**Error**: `Cannot find 'openWindow' in scope`
**Solution**: This is macOS-only. iOS uses sheets instead.

### Runtime Issues

**Issue**: Windows don't open
**Solution**: Verify window IDs match in both openWindow() calls and Scene definitions

**Issue**: Data not syncing between windows
**Solution**: Ensure environment objects are properly passed to all windows

## Migration Notes

### From Previous Version

The old combined "Files" window has been split into two separate windows. The FilesView component is still used for iOS sheets but not for macOS windows.

### iOS Compatibility

iOS behavior is unchanged - still uses sheets with tabs for Library/Player.

## References

- [SwiftUI Window Management](https://developer.apple.com/documentation/swiftui/window)
- [WindowGroup Documentation](https://developer.apple.com/documentation/swiftui/windowgroup)
- [openWindow Environment Action](https://developer.apple.com/documentation/swiftui/environmentvalues/openwindow)
