# Window Configuration Reference

## SwiftUI Window Modifiers for macOS

### Fullscreen Support

The Library and Player windows now support fullscreen mode using these modifiers:

```swift
Window("Library", id: "library") {
    LibraryWindowView()
}
.defaultSize(width: 1200, height: 800)          // Large default size
.windowResizability(.contentSize)                // Allow resizing
.windowFullScreenBehavior(.enabled)              // Enable fullscreen button
```

## Window Modifiers Explained

### 1. `.defaultSize(width:height:)`
Sets the initial size when the window first opens.

**Examples:**
```swift
.defaultSize(width: 1200, height: 800)   // Large window
.defaultSize(width: 600, height: 400)    // Small window
```

### 2. `.windowResizability()`
Controls whether and how the window can be resized.

**Options:**
- `.contentSize` - Window can be resized, respects content constraints
- `.automatic` - System decides resizability
- `.contentMinSize` - Can't shrink below content minimum size

**Examples:**
```swift
.windowResizability(.contentSize)        // User can resize freely
.windowResizability(.contentMinSize)     // Fixed to minimum content size
```

### 3. `.windowFullScreenBehavior()`
Controls fullscreen mode availability.

**Options:**
- `.enabled` - Shows green fullscreen button (⚫️🟢🔴)
- `.disabled` - Hides fullscreen button
- `.automatic` - System decides

**Examples:**
```swift
.windowFullScreenBehavior(.enabled)      // Fullscreen available
.windowFullScreenBehavior(.disabled)     // No fullscreen option
```

### 4. `.windowStyle()`
Controls the window's appearance style.

**Options:**
- `.hiddenTitleBar` - Hides the title bar
- `.titleBar` - Shows standard title bar
- `.automatic` - System default

**Examples:**
```swift
.windowStyle(.hiddenTitleBar)            // Clean, modern look
.windowStyle(.titleBar)                  // Traditional macOS window
```

## Current Window Configuration

### Main Recording Window
```swift
WindowGroup(id: "main") {
    ContentView()
}
.windowStyle(.hiddenTitleBar)
.windowResizability(.contentSize)
```
- Clean interface without title bar
- Resizable to fit content

### Library Window
```swift
Window("Library", id: "library") {
    LibraryWindowView()
}
.defaultSize(width: 1200, height: 800)
.windowResizability(.contentSize)
.windowFullScreenBehavior(.enabled)
```
- **Large initial size** (1200×800)
- **Fullscreen capable** (green button available)
- User can resize as needed

### Player Window
```swift
Window("Player", id: "player") {
    PlayerWindowView()
}
.defaultSize(width: 1000, height: 800)
.windowResizability(.contentSize)
.windowFullScreenBehavior(.enabled)
```
- **Large initial size** (1000×800)
- **Fullscreen capable** (green button available)
- User can resize as needed

### Settings Window
```swift
Window("Settings", id: "settings") {
    SettingsWindowView()
}
.defaultSize(width: 600, height: 700)
```
- Medium-sized window
- No fullscreen (settings don't need it)

### Transcription Window
```swift
WindowGroup(id: "transcription", for: String.self) {
    TranscriptionWindowView(...)
}
.defaultSize(width: 600, height: 500)
```
- Compact window for text viewing
- Can open multiple instances

## Using Fullscreen

### For Users

1. **Enter Fullscreen:**
   - Click the green button (🟢) in window controls
   - Or press `Control + Command + F`
   - Window expands to fill entire screen

2. **Exit Fullscreen:**
   - Move mouse to top of screen to reveal controls
   - Click green button again
   - Or press `Control + Command + F`

3. **Gesture:**
   - Swipe up with three fingers to show all spaces
   - Swipe left/right to switch between fullscreen windows

## Additional Window Modifiers

### Making Window Non-Resizable
```swift
.windowResizability(.contentMinSize)
```

### Custom Toolbar
```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Action") { }
    }
}
```

### Commands Menu
```swift
.commands {
    CommandGroup(replacing: .newItem) {
        Button("New Recording") { }
            .keyboardShortcut("n")
    }
}
```

## Best Practices

### When to Use Fullscreen

✅ **Use fullscreen for:**
- Library window (browsing many recordings)
- Player window (detailed controls)
- Content-heavy windows
- Windows users might want to focus on

❌ **Don't use fullscreen for:**
- Settings windows (quick access)
- Alert/modal windows
- Small utility windows
- Secondary/helper windows

### Window Sizing Guidelines

**Small Windows** (400-600px)
- Settings
- Alerts
- Simple forms

**Medium Windows** (600-800px)
- Content viewers
- Transcription display
- Single-purpose tools

**Large Windows** (800-1200px)
- Library/collection views
- Editing interfaces
- Multi-column layouts
- Main application windows

## Programmatic Fullscreen

If you want to programmatically toggle fullscreen from code:

### SwiftUI (macOS 13+)
```swift
@Environment(\.openWindow) private var openWindow

// In AppKit, you would use:
// NSWindow.toggleFullScreen(_:)
```

### Using NSWindow (AppKit bridge)
```swift
#if os(macOS)
import AppKit

extension View {
    func toggleFullscreen() {
        if let window = NSApp.keyWindow {
            window.toggleFullScreen(nil)
        }
    }
}
#endif
```

## Migration Notes

### Before
Windows had small fixed sizes, no fullscreen support.

### After
- Library: 1200×800 with fullscreen ✅
- Player: 1000×800 with fullscreen ✅
- Improved usability for content-heavy windows

## Testing Fullscreen

### Manual Testing
1. Open Library window
2. Check for green fullscreen button in window controls
3. Click it to enter fullscreen
4. Verify window fills entire screen
5. Click again or press Esc to exit

### Keyboard Shortcuts
- `Control + Command + F` - Toggle fullscreen
- `Control + Up Arrow` - Mission Control (view all windows)
- `Control + Left/Right Arrow` - Switch spaces

## References

- [Window Documentation](https://developer.apple.com/documentation/swiftui/window)
- [windowFullScreenBehavior](https://developer.apple.com/documentation/swiftui/scene/windowfullscreenbehavior(_:))
- [windowResizability](https://developer.apple.com/documentation/swiftui/scene/windowresizability(_:))
- [defaultSize](https://developer.apple.com/documentation/swiftui/scene/defaultsize(width:height:))
