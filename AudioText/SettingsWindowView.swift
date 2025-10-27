import SwiftUI

struct SettingsWindowView: View {
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    @EnvironmentObject private var openAIService: OpenAIService
    @Environment(\.dismiss) private var dismiss

    @State private var transcriptionMethod: TranscriptionMethod = .builtIn
    @State private var selectedLanguageCode: String = "auto"
    @State private var selectedTextStyle: String = "Any changes"
    @State private var apiKey: String = ""

    var body: some View {
        SettingsView(
            transcriptionMethod: $transcriptionMethod,
            selectedLanguageCode: $selectedLanguageCode,
            selectedTextStyle: $selectedTextStyle,
            apiKey: $apiKey
        )
        .environmentObject(audioRecorder)
        .environmentObject(speechRecognizer)
        .environmentObject(openAIService)
        .frame(minWidth: 500, minHeight: 600)
    }
}
