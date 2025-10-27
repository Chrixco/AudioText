# AudioText

A cross-platform audio-to-text application built with Swift and SwiftUI, featuring a beautiful neumorphic design and powered by OpenAI's Whisper API.

## Features

- 🎤 **Real-time Audio Recording** - High-quality audio capture using AVAudioEngine
- 🤖 **AI-Powered Transcription** - Accurate speech-to-text using OpenAI Whisper
- 🎨 **Neumorphic Design** - Modern, minimalist UI with soft shadows and depth
- 📱 **Cross-Platform** - Native iOS and macOS applications
- 🔒 **Secure** - API keys stored securely using environment variables
- ⚡ **Fast & Responsive** - Optimized for performance and user experience

## Architecture

The app follows a clean MVVM architecture:

- **Models**: Data entities for transcription results and audio files
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI components with neumorphic styling
- **Services**: Audio recording and Whisper API integration

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- OpenAI API key

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/AudioText.git
cd AudioText
```

### 2. Configure API Key

Set your OpenAI API key as an environment variable:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

Or add it to your Xcode scheme:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add `OPENAI_API_KEY` with your API key value

### 3. Build and Run

```bash
# Build for iOS
xcodebuild -scheme AudioText -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for macOS
xcodebuild -scheme "AudioText macOS" -destination 'platform=macOS'
```

## Development

### Project Structure

```
AudioText/
├── AudioText/                    # iOS app
│   ├── AudioTextApp.swift        # App entry point
│   ├── ContentView.swift         # Main UI
│   ├── Design/                   # Neumorphic design system
│   ├── ViewModels/               # MVVM ViewModels
│   ├── Services/                 # Audio and API services
│   └── Models/                   # Data models
├── AudioText macOS/              # macOS app
├── AudioTextTests/               # Unit tests
└── AudioTextUITests/             # UI tests
```

### Key Components

#### Neumorphic Design System
- `NeumorphicColors.swift` - Color palette for neumorphic theme
- `NeumorphicButton.swift` - Reusable button component with soft shadows

#### Audio Recording
- `AudioRecorder.swift` - Handles microphone input and audio processing
- Uses AVAudioEngine for high-quality recording
- Automatic permission handling

#### Whisper Integration
- `WhisperService.swift` - OpenAI API client
- Supports multiple audio formats
- Error handling and retry logic

### Testing

Run the test suite:

```bash
# Unit tests
xcodebuild test -scheme AudioText -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests
xcodebuild test -scheme AudioText -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:AudioTextUITests
```

### Code Style

- Follow Apple's Swift API Design Guidelines
- Use SwiftFormat for consistent formatting
- Maintain 80%+ test coverage
- Document public APIs

## Security

- API keys are never committed to the repository
- Use environment variables or secure keychain storage
- All network requests use HTTPS
- Audio data is processed locally before transmission

## Deployment

### App Store Preparation

1. Update version numbers in project settings
2. Configure code signing certificates
3. Archive the app for distribution
4. Upload to App Store Connect

### Environment Configuration

Create a `.env.example` file:

```
OPENAI_API_KEY=your-api-key-here
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the documentation
- Review the test cases for usage examples

## Roadmap

- [ ] Offline transcription support
- [ ] Multiple language detection
- [ ] Export to various formats
- [ ] Batch processing
- [ ] Custom audio settings
- [ ] Voice activity detection
- [ ] Real-time transcription streaming
