import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var openAIService = OpenAIService()

    @State private var showingSettings = false
    @State private var showingFiles = false
    @State private var showingTranscription = false

    @State private var transcriptionMethod: TranscriptionMethod = .builtIn
    @State private var selectedLanguageCode: String = "auto"
    @State private var selectedTextStyle: String = "Any changes"
    @State private var apiKey: String = ""

    @State private var currentTranscription = ""
    @State private var transcriptionErrorMessage: String?
    @State private var isProcessingTranscription = false
    @State private var lastProcessedRecordingID: UUID?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    recordingStatusView
                    Spacer()
                    audioVisualizerView
                    Spacer()
                    statusInfoView
                }
                .padding()

                bottomButtons
            }
            .frame(minWidth: 720, minHeight: 600)
            .navigationTitle("AudioText")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    settingsMenu
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                transcriptionMethod: $transcriptionMethod,
                selectedLanguageCode: $selectedLanguageCode,
                selectedTextStyle: $selectedTextStyle,
                apiKey: $apiKey
            )
            .environmentObject(audioRecorder)
            .environmentObject(speechRecognizer)
            .environmentObject(openAIService)
            .frame(minWidth: 420, minHeight: 480)
        }
        .sheet(isPresented: $showingFiles) {
            FilesView()
                .environmentObject(audioRecorder)
                .environmentObject(audioPlayer)
                .frame(minWidth: 600, minHeight: 500)
        }
        .sheet(isPresented: $showingTranscription) {
            TranscriptionView(transcription: currentTranscription)
                .frame(minWidth: 500, minHeight: 400)
        }
        .alert("Recording Error", isPresented: recordingErrorBinding) {
            Button("OK", role: .cancel) {
                audioRecorder.recordingError = nil
            }
        } message: {
            if let error = audioRecorder.recordingError?.localizedDescription {
                Text(error)
            }
        }
        .alert("Playback Error", isPresented: playbackErrorBinding) {
            Button("OK", role: .cancel) {
                audioPlayer.playbackError = nil
            }
        } message: {
            if let error = audioPlayer.playbackError?.localizedDescription {
                Text(error)
            }
        }
        .alert("Transcription Error", isPresented: transcriptionErrorBinding) {
            Button("OK", role: .cancel) {
                transcriptionErrorMessage = nil
            }
        } message: {
            if let message = transcriptionErrorMessage {
                Text(message)
            }
        }
        .onChange(of: apiKey) { _, newValue in
            openAIService.setAPIKey(newValue)
        }
    }

    private var recordingStatusView: some View {
        VStack(spacing: 16) {
            if audioRecorder.isRecording {
                VStack(spacing: 8) {
                    Text("Recording…")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("\(Int(audioRecorder.recordingTime)) s")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            } else if isProcessingTranscription {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Transcribing latest clip…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if !currentTranscription.isEmpty {
                VStack(spacing: 8) {
                    Text("Latest transcription ready")
                        .font(.headline)
                    Button("View transcription") {
                        showingTranscription = true
                    }
                    .font(.subheadline)
                }
            } else {
                Text("Ready to record")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
    }

    private var audioVisualizerView: some View {
        VStack(spacing: 24) {
            if audioRecorder.isRecording {
                AudioVisualizer(
                    isActive: audioRecorder.isRecording,
                    levelProvider: { audioRecorder.currentLevel() }
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.08))
                )
                .padding(.horizontal, 48)
            } else if audioPlayer.isPlaying {
                AudioVisualizer(
                    isActive: true,
                    levelProvider: { audioPlayer.currentLevel() }
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.08))
                )
                .padding(.horizontal, 48)
            }

            Button(action: toggleRecording) {
                VStack(spacing: audioRecorder.isRecording ? 6 : 10) {
                    Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(.white)
                    Text(audioRecorder.isRecording ? "Stop" : "Record")
                        .font(.headline)
                        .foregroundStyle(.white)
                    if audioRecorder.isRecording {
                        Text(formattedRecordingTime)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                            .monospacedDigit()
                    }
                }
                .frame(width: 180, height: 180)
                .background(audioRecorder.isRecording ? Color.red : Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusInfoView: some View {
        VStack(spacing: 12) {
            Text("Audio Recording")
                .font(.headline)
            Text(audioRecorder.isRecording ? "Tap stop to finish your clip." : "Tap record to start capturing audio.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 32)
    }

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button(action: toggleRecording) {
                Label(audioRecorder.isRecording ? "Pause" : "Record", systemImage: audioRecorder.isRecording ? "pause.fill" : "mic.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(audioRecorder.isRecording ? Color.orange : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button(action: secondaryButtonAction) {
                Label(audioRecorder.isRecording ? "Delete" : "Files", systemImage: audioRecorder.isRecording ? "trash.fill" : "folder.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(audioRecorder.isRecording ? Color.red : Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding()
    }

    private var settingsMenu: some View {
        Menu {
            Button {
                showingFiles = true
            } label: {
                Label("Files", systemImage: "folder")
            }

            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }

            if !currentTranscription.isEmpty {
                Button {
                    showingTranscription = true
                } label: {
                    Label("Transcription", systemImage: "text.bubble")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            if let recording = audioRecorder.stopRecording() {
                processTranscription(for: recording)
            }
        } else {
            Task { await audioRecorder.startRecording() }
        }
    }

    private var formattedRecordingTime: String {
        let totalSeconds = Int(audioRecorder.recordingTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func secondaryButtonAction() {
        if audioRecorder.isRecording {
            if let recording = audioRecorder.stopRecording() {
                try? FileManager.default.removeItem(at: recording.fileURL)
                audioRecorder.recordings.removeAll { $0.id == recording.id }
            }
        } else {
            showingFiles = true
        }
    }

    private func processTranscription(for recording: RecordingFile) {
        guard lastProcessedRecordingID != recording.id else { return }

        isProcessingTranscription = true
        transcriptionErrorMessage = nil

        Task {
            defer {
                Task { @MainActor in
                    isProcessingTranscription = false
                    lastProcessedRecordingID = recording.id
                }
            }

            let language = selectedLanguageCode.isEmpty ? "auto" : selectedLanguageCode

            do {
                let text: String
                switch transcriptionMethod {
                case .builtIn:
                    text = try await speechRecognizer.transcribeAudio(from: recording.fileURL, language: language)
                case .openAI:
                    text = try await openAIService.transcribeAudio(
                        from: recording.fileURL,
                        language: language,
                        textStyle: selectedTextStyle
                    )
                }

                Task { @MainActor in
                    audioRecorder.attachTranscript(text, to: recording)
                    currentTranscription = text
                    showingTranscription = true
                }
            } catch {
                Task { @MainActor in
                    transcriptionErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private var recordingErrorBinding: Binding<Bool> {
        Binding(
            get: { audioRecorder.recordingError != nil },
            set: { _ in audioRecorder.recordingError = nil }
        )
    }

    private var playbackErrorBinding: Binding<Bool> {
        Binding(
            get: { audioPlayer.playbackError != nil },
            set: { _ in audioPlayer.playbackError = nil }
        )
    }

    private var transcriptionErrorBinding: Binding<Bool> {
        Binding(
            get: { transcriptionErrorMessage != nil },
            set: { value in
                if !value { transcriptionErrorMessage = nil }
            }
        )
    }
}

struct TranscriptionView: View {
    let transcription: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(transcription.isEmpty ? "No transcription available yet." : transcription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Transcription")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
