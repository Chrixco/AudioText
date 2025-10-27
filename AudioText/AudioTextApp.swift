import SwiftUI
import Speech

@main
struct AudioTextApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Add a small delay to ensure the app is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        requestPermissions()
                    }
                }
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
