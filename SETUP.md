# AudioText Setup Guide

## ✅ Project Fixed!

The Xcode project has been completely rebuilt with the correct structure. The previous error was caused by malformed project file references.

## 🚀 Quick Start

### 1. Open the Project
```bash
open AudioText.xcodeproj
```

### 2. Set Your API Key
Before running the app, you need to set your OpenAI API key:

**Option A: Environment Variable**
```bash
export OPENAI_API_KEY="your-api-key-here"
```

**Option B: Xcode Scheme Settings**
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add `OPENAI_API_KEY` with your API key value

### 3. Build and Run
- **iOS**: Select "AudioText" scheme and press Cmd+R
- **macOS**: Select "AudioText macOS" scheme and press Cmd+R

## 📁 Project Structure

```
AudioText/
├── AudioText/                    # iOS app
│   ├── AudioTextApp.swift        # App entry point
│   ├── ContentView.swift         # Main UI
│   ├── Design/                   # Neumorphic design system
│   │   ├── NeumorphicColors.swift
│   │   └── NeumorphicButton.swift
│   ├── ViewModels/               # MVVM ViewModels
│   │   └── AudioTextViewModel.swift
│   ├── Services/                 # Audio and API services
│   │   ├── AudioRecorder.swift
│   │   └── WhisperService.swift
│   ├── Models/                   # Data models
│   │   └── TranscriptionResult.swift
│   └── Assets.xcassets/         # App assets
├── AudioText macOS/              # macOS app
├── AudioTextTests/               # Unit tests
├── AudioTextUITests/             # UI tests
└── scripts/build.sh              # Build automation
```

## 🎨 Features

- **Neumorphic Design**: Beautiful soft shadows and depth effects
- **Cross-Platform**: Native iOS and macOS apps
- **AI Transcription**: Powered by OpenAI Whisper API
- **Real-time Recording**: High-quality audio capture
- **Secure**: API keys stored in environment variables

## 🧪 Testing

Run tests using the build script:
```bash
./scripts/build.sh test
```

Or in Xcode:
- Press Cmd+U to run all tests
- Select specific test targets in the scheme editor

## 🔧 Development

### Build Commands
```bash
./scripts/build.sh ios      # Build for iOS
./scripts/build.sh macos    # Build for macOS
./scripts/build.sh test     # Run tests
./scripts/build.sh clean    # Clean build folder
./scripts/build.sh all      # Clean, build, and test everything
```

### Code Style
- SwiftFormat configuration included
- Follow Apple's Swift API Design Guidelines
- Maintain 80%+ test coverage

## 🚨 Troubleshooting

### Common Issues

1. **"Project is damaged" error**
   - ✅ **Fixed**: Project file has been completely rebuilt

2. **API Key not found**
   - Set `OPENAI_API_KEY` environment variable
   - Or add it to Xcode scheme settings

3. **Microphone permission denied**
   - Check System Preferences → Security & Privacy → Microphone
   - Ensure AudioText has microphone access

4. **Build errors**
   - Clean build folder: Cmd+Shift+K
   - Reset derived data: Xcode → Preferences → Locations → Derived Data

## 📱 App Store Preparation

1. **Update version numbers** in project settings
2. **Configure code signing** certificates
3. **Archive the app** for distribution
4. **Upload to App Store Connect**

## 🎯 Next Steps

1. Open the project in Xcode
2. Set your OpenAI API key
3. Build and run on simulator/device
4. Test the recording and transcription features
5. Customize the neumorphic design if needed

The project is now ready for development! 🎉
