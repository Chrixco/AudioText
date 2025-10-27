# iOS Fullscreen Presentation

## Overview

On iOS, Library, Player, and Transcription now use **fullscreen presentation** (`.fullScreenCover()`), while Settings remains as a **sheet** (`.sheet()`).

## Presentation Styles

### Before (All Sheets)
All views were presented as floating sheets that covered ~50-80% of the screen.

### After (Mixed)

#### Fullscreen Presentation
- **Library** - Takes entire screen ✅
- **Player** - Takes entire screen ✅
- **Transcription** - Takes entire screen ✅

#### Sheet Presentation
- **Settings** - Floating sheet (unchanged) ✅
- **ShareSheet** - System sheet (unchanged) ✅

## SwiftUI Code Comparison

### Fullscreen Presentation
```swift
.fullScreenCover(isPresented: $showingLibrarySheet) {
    filesSheet
}
```

**Behavior:**
- Covers entire screen edge-to-edge
- Modal presentation with slide-up animation
- Dismiss by swiping down or close button
- Full immersion in content

### Sheet Presentation
```swift
.sheet(isPresented: $showingSettings) {
    SettingsView(...)
}
```

**Behavior:**
- Covers ~50-80% of screen
- Shows previous view dimmed behind
- Dismiss by pulling down
- Better for quick settings/forms

## User Experience

### Library Fullscreen
**Why:** Users need to browse many recordings, fullscreen provides maximum space

**Features:**
- See more recordings at once
- No distraction from main view
- Immersive browsing experience
- Easy tap-to-close with X button

### Player Fullscreen
**Why:** Equalizer needs space for controls

**Features:**
- Full view of equalizer bands
- Large playback controls
- Waveform visualization
- No cramped interface

### Transcription Fullscreen
**Why:** Reading text benefits from fullscreen

**Features:**
- Maximum reading area
- No background distractions
- Easy to focus on content
- Swipe down to dismiss

### Settings as Sheet
**Why:** Quick access, doesn't need full screen

**Features:**
- Quick changes without losing context
- See main view behind (dimmed)
- Familiar iOS settings pattern
- Easy pull-down to dismiss

## How It Works

### Opening Library (Fullscreen)
```swift
// User taps Library button
Button {
    showingLibrarySheet = true  // Triggers fullScreenCover
} label: {
    Label("Library", systemImage: "music.note.list")
}
```

### Opening Settings (Sheet)
```swift
// User taps Settings in menu
Button {
    showingSettings = true  // Triggers sheet
} label: {
    Label("Settings", systemImage: "gear")
}
```

## Implementation Details

### ContentView.swift Changes

**Added Fullscreen Modifiers:**
```swift
#if os(iOS)
    // Fullscreen for Library/Player
    .fullScreenCover(isPresented: $showingLibrarySheet) {
        filesSheet
    }

    // Sheet for Settings
    .sheet(isPresented: $showingSettings) {
        SettingsView(...)
    }

    // Fullscreen for Transcription
    .fullScreenCover(isPresented: $showingTranscription) {
        TranscriptionView(transcription: currentTranscription)
    }
#endif
```

## Dismiss Gestures

### Fullscreen Views
1. **Swipe down from top** - Dismisses view
2. **Tap X/Close button** - Explicit dismiss
3. **Back navigation** - If in navigation stack

### Sheet Views
1. **Pull down** - Dismisses sheet
2. **Tap outside** - Dismisses on iPad
3. **Close button** - Explicit dismiss

## Platform Differences

### iOS
- Uses `.fullScreenCover()` for immersive views
- Uses `.sheet()` for quick access views
- Swipe gestures to dismiss

### macOS
- Uses separate `Window` scenes
- Each window is independent
- Standard window controls (minimize, maximize, close)

## Benefits

### User Benefits
- ✅ **More screen space** for Library browsing
- ✅ **Better focus** on Player controls
- ✅ **Easier reading** of Transcription
- ✅ **Quick settings** access with sheet
- ✅ **Consistent iOS patterns** (fullscreen for content, sheets for forms)

### Developer Benefits
- ✅ **Simple presentation style** - just change `.sheet()` to `.fullScreenCover()`
- ✅ **Same state management** - uses same `@State` variables
- ✅ **Platform appropriate** - iOS uses covers, macOS uses windows
- ✅ **Easy to modify** - centralized presentation logic

## Testing

### Manual Test Checklist

#### Library Fullscreen
- [ ] Tap Library button
- [ ] View slides up and covers entire screen
- [ ] No peek at main view behind
- [ ] Can swipe down to dismiss
- [ ] Close button works

#### Player Fullscreen
- [ ] Switch to Player tab in Library
- [ ] Takes full screen
- [ ] Equalizer is fully visible
- [ ] Can dismiss back to main

#### Transcription Fullscreen
- [ ] After recording, tap transcription chip
- [ ] Text view takes full screen
- [ ] Easy to read full content
- [ ] Swipe down dismisses

#### Settings Sheet
- [ ] Tap menu → Settings
- [ ] Opens as floating sheet
- [ ] Can see dimmed main view behind
- [ ] Pull down to dismiss works

## Troubleshooting

### View doesn't cover full screen
**Issue:** Library opens as sheet instead of fullscreen
**Solution:** Verify using `.fullScreenCover()` not `.sheet()`

### Can't dismiss fullscreen view
**Issue:** Swipe down doesn't work
**Solution:** Ensure view has close button as backup

### Settings opens fullscreen
**Issue:** Settings should be sheet but opens fullscreen
**Solution:** Check that Settings uses `.sheet()` modifier

## Future Enhancements

- [ ] Custom transition animations
- [ ] Haptic feedback on dismiss
- [ ] Gesture-based navigation between Library/Player
- [ ] Picture-in-picture mode for Player
- [ ] Split view on iPad

## References

- [fullScreenCover Documentation](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:))
- [sheet Documentation](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:))
- [Human Interface Guidelines - Modal Presentations](https://developer.apple.com/design/human-interface-guidelines/modality)

## Migration Guide

### From Sheet to Fullscreen

**Before:**
```swift
.sheet(isPresented: $showingLibrary) {
    LibraryView()
}
```

**After:**
```swift
.fullScreenCover(isPresented: $showingLibrary) {
    LibraryView()
}
```

That's it! Just change the modifier name - same state binding, same content.
