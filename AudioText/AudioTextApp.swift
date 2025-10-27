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
                    // Add a small delay to ensure the app is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        requestPermissions()
                    }
                }
        }

        // Settings Window
        WindowGroup(id: "settings") {
            SettingsWindowView()
                .environmentObject(audioRecorder)
                .environmentObject(speechRecognizer)
                .environmentObject(openAIService)
        }

        // Files/Library Window
        WindowGroup(id: "files") {
            FilesView()
                .environmentObject(audioRecorder)
                .environmentObject(audioPlayer)
        }

        // Transcription Window
        WindowGroup(id: "transcription", for: String.self) { $transcription in
            TranscriptionWindowView(transcription: transcription ?? "")
        }
    }

    private func requestPermissions() {
        // Request speech recognition permission
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
