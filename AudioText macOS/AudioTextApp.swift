import SwiftUI
import Speech

@main
struct AudioTextApp: App {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var openAIService = OpenAIService()

    var body: some Scene {
        // Main Recording Window
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(audioRecorder)
                .environmentObject(audioPlayer)
                .environmentObject(speechRecognizer)
                .environmentObject(openAIService)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        requestPermissions()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // Settings Window
        Window("Settings", id: "settings") {
            SettingsWindowView()
                .environmentObject(audioRecorder)
                .environmentObject(speechRecognizer)
                .environmentObject(openAIService)
        }
        .defaultSize(width: 600, height: 700)

        // Library Window
        Window("Library", id: "library") {
            LibraryWindowView()
                .environmentObject(audioRecorder)
                .environmentObject(audioPlayer)
        }
        .defaultSize(width: 1200, height: 800)
        .windowResizability(.contentSize)
        .windowFullScreenBehavior(.enabled)

        // Player Window
        Window("Player", id: "player") {
            PlayerWindowView()
                .environmentObject(audioRecorder)
                .environmentObject(audioPlayer)
        }
        .defaultSize(width: 1000, height: 800)
        .windowResizability(.contentSize)
        .windowFullScreenBehavior(.enabled)

        // Transcription Window
        WindowGroup(id: "transcription", for: String.self) { $transcription in
            TranscriptionWindowView(transcription: transcription ?? "")
        }
        .defaultSize(width: 600, height: 500)
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition permission granted")
                case .denied:
                    print("❌ Speech recognition permission denied")
                case .restricted:
                    print("⚠️ Speech recognition permission restricted")
                case .notDetermined:
                    print("❓ Speech recognition permission not determined")
                @unknown default:
                    print("❓ Speech recognition permission unknown status")
                }
            }
        }
    }
}

