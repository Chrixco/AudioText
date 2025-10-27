import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    @EnvironmentObject private var openAIService: OpenAIService

    @Environment(\.openWindow) private var openWindow

    @State private var transcriptionMethod: TranscriptionMethod = .builtIn
    @State private var selectedLanguageCode: String = "auto"
    @State private var selectedTextStyle: String = "Any changes"
    @State private var apiKey: String = ""

    @State private var currentTranscription = ""
    @State private var transcriptionErrorMessage: String?
    @State private var isProcessingTranscription = false
    @State private var lastProcessedRecordingID: UUID?

    // iOS sheet presentation states
    @State private var showingSettings = false
    @State private var showingTranscription = false
    @State private var showingLibrarySheet = false
    @State private var filesSubpanel: FilesSubpanel = .list
    @State private var quickSelectedRecordingID: UUID?
    @State private var panelScriptRecording: RecordingFile?
    @State private var showingRenameAlert = false
    @State private var recordingToRename: RecordingFile?
    @State private var renameText = ""
    @State private var renameError: String?
    @State private var showingShareSheet = false
    @State private var recordingToShare: RecordingFile?

    private enum FilesSubpanel: Int, CaseIterable, Identifiable {
        case list
        case equalizer

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .list: return "Library"
            case .equalizer: return "Player"
            }
        }

        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .equalizer: return "play.circle"
            }
        }
    }

    var body: some View {
        NavigationStack {
            recordPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(backgroundColor)
                .navigationTitle("AudioText")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        settingsMenu
                    }
                }
        }
        .background(backgroundColor)
#if os(iOS)
        // iOS uses sheets for modal presentation
        .sheet(isPresented: $showingLibrarySheet) {
            filesSheet
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
        }
        .sheet(isPresented: $showingTranscription) {
            TranscriptionView(transcription: currentTranscription)
        }
        .sheet(item: $panelScriptRecording) { recording in
            TranscriptionView(
                transcription: recording.transcript ?? "No transcript is available for this recording yet."
            )
        }
#endif
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
        .alert("Rename Recording", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                recordingToRename = nil
                renameText = ""
                renameError = nil
            }
            Button("Rename") {
                performRename()
            }
        } message: {
            if let error = renameError {
                Text(error)
            } else {
                Text("Enter a new name for the recording")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let recording = recordingToShare {
                ShareSheet(items: [recording.fileURL])
            }
        }
        .onChange(of: apiKey) { _, newValue in
            openAIService.setAPIKey(newValue)
        }
        .onChange(of: audioRecorder.recordings) { _, _ in
            refreshPanelSelection()
        }
        .onChange(of: quickSelectedRecordingID) { _, _ in
            panelScriptRecording = nil
        }
        .onAppear {
            refreshPanelSelection()
        }
    }

    private var backgroundColor: Color {
#if os(iOS)
        Color(uiColor: .systemBackground)
#else
        Color(nsColor: .windowBackgroundColor)
#endif
    }

    private var recordPanel: some View {
        VStack(spacing: 24) {
            statusBanner
#if os(iOS)
            languageInputStack
#endif
            audioVisualizerView

            if !currentTranscription.isEmpty {
                transcriptionChip
            }

            recordingHelperText
            libraryButton

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }

    private var statusInfo: (title: String, subtitle: String?, color: Color, icon: String) {
        if audioRecorder.isRecording {
            return ("Recording in progress", "Tap stop when you're done.", .red, "record.circle")
        }

        if isProcessingTranscription {
            return ("Transcribing latest clip…", "You can keep capturing new notes.", .blue, "waveform")
        }

        if !currentTranscription.isEmpty {
            return ("Latest transcription ready", "Preview or share it below.", .green, "checkmark.seal")
        }

        return ("Ready to capture audio", "Adjust input and tap the mic to begin.", Color.accentColor, "mic.circle")
    }

    private var statusBanner: some View {
        let info = statusInfo
        return HStack(alignment: .center, spacing: 12) {
            Image(systemName: info.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(info.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(info.title)
                    .font(.headline)
                if let subtitle = info.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(info.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(info.color.opacity(0.2), lineWidth: 1)
        )
    }

#if os(iOS)
    @ViewBuilder
    private var languageInputStack: some View {
        VStack(spacing: 12) {
            languageSelector
            inputModeSelector
        }
    }
#endif

    private var transcriptionChip: some View {
        Button {
            showingTranscription = true
        } label: {
            Label("View latest transcription", systemImage: "text.bubble")
                .font(.subheadline.bold())
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }

    private var recordingHelperText: some View {
        let message: String
        if audioRecorder.isRecording {
            message = "Recording… tap the center button when you're finished."
        } else if isProcessingTranscription {
            message = "We’re preparing the last transcript while you get ready for the next clip."
        } else {
            message = "Tap the mic to start a new note. Rotate the knob to scrub during playback."
        }

        return Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var libraryButton: some View {
        Button {
#if os(macOS)
            openWindow(id: "files")
#else
            filesSubpanel = .list
            showingLibrarySheet = true
#endif
        } label: {
            Label("Library", systemImage: "music.note.list")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
        .shadow(color: Color.accentColor.opacity(0.25), radius: 10, x: 0, y: 6)
    }

    private var filesListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label("Library", systemImage: "music.note.list")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if audioRecorder.recordings.isEmpty {
                    filesPanelEmptyState
                } else {
                    VStack(spacing: 16) {
                        ForEach(audioRecorder.recordings) { recording in
                            RecordingListRow(
                                recording: recording,
                                isSelected: recording.id == selectedPanelRecording?.id,
                                equalizerSettings: audioRecorder.equalizerSettings(for: recording),
                                onPlayTapped: {
                                    quickSelectedRecordingID = recording.id
                                    filesSubpanel = .equalizer
                                    togglePlayback(for: recording)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                quickSelectedRecordingID = recording.id
                            }
                            .contextMenu {
                                Button {
                                    startRename(recording)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button {
                                    shareRecording(recording)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                Button(role: .destructive) {
                                    deleteRecording(recording)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var filesEqualizerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label("Player", systemImage: "play.circle")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let recording = selectedPanelRecording {
                    let scriptBinding = Binding<Bool>(
                        get: { panelScriptRecording?.id == recording.id },
                        set: { newValue in
                            if newValue {
                                panelScriptRecording = recording
                            } else if panelScriptRecording?.id == recording.id {
                                panelScriptRecording = nil
                            }
                        }
                    )

                    RecordingDetailCard(
                        recording: recording,
                        showingScript: scriptBinding,
                        togglePlayback: { togglePlayback(for: recording) },
                        equalizerSettings: audioRecorder.equalizerSettings(for: recording),
                        onSaveEqualizer: { settings in
                            audioRecorder.updateEqualizerSettings(settings, for: recording)
                        }
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "waveform")
                            .font(.system(size: 60, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("No recordings yet")
                            .font(.title3.weight(.semibold))
                        Text("Capture a clip on the Record tab to start tuning your custom equalizer profile.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var filesPanelEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No recordings yet")
                .font(.title3.weight(.semibold))
            Text("Capture audio on the Record tab to see your files here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private var selectedPanelRecording: RecordingFile? {
        if let id = quickSelectedRecordingID {
            return audioRecorder.recordings.first { $0.id == id }
        }
        return audioRecorder.recordings.first
    }

    private func refreshPanelSelection() {
        if let id = quickSelectedRecordingID,
           audioRecorder.recordings.contains(where: { $0.id == id }) {
            return
        }
        quickSelectedRecordingID = audioRecorder.recordings.first?.id
    }

    private var filesSheet: some View {
#if os(iOS)
        filesSheetBase
            .presentationDetents([.fraction(0.45), .large])
            .presentationDragIndicator(.visible)
#else
        filesSheetBase
#endif
    }

    @ViewBuilder
    private var filesSheetBase: some View {
        NavigationStack {
            VStack(spacing: 20) {
                filesSubpanelPicker

                Group {
                    switch filesSubpanel {
                    case .list:
                        filesListView
                    case .equalizer:
                        filesEqualizerView
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(backgroundColor)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingLibrarySheet = false }
                }
            }
        }
    }

    private var filesSubpanelPicker: some View {
        Picker("Files section", selection: $filesSubpanel) {
            ForEach(FilesSubpanel.allCases) { subpanel in
                Label(subpanel.title, systemImage: subpanel.icon)
                    .tag(subpanel)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)
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
                    .padding(.horizontal, 32)
            }

            Button(action: toggleRecording) {
                VStack(spacing: audioRecorder.isRecording ? 4 : 8) {
                    Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40, weight: .bold))
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
                .frame(width: 150, height: 150)
                .background(audioRecorder.isRecording ? .red : .blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel(audioRecorder.isRecording ? "Stop recording" : "Start recording")
        }
    }

#if os(iOS)
    private var inputModeSelector: some View {
        InputModeSelectorView(
            selectedMode: audioRecorder.inputMode,
            isExternalAvailable: audioRecorder.isExternalInputAvailable,
            isBluetoothAvailable: audioRecorder.isBluetoothAvailable,
            onSelect: { mode in audioRecorder.setInputMode(mode) }
        )
    }

    private var languageSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Language")
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                let options = availableLanguageOptions
                ForEach(options) { option in
                    Button(option.label) {
                        selectedLanguageCode = option.code
                    }
                }
            } label: {
                HStack {
                    Text(languageLabel(for: selectedLanguageCode))
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.blue.opacity(0.08))
                )
            }

            Text(languageHelperText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var availableLanguageOptions: [LanguageOption] {
        LanguageOption.options(for: transcriptionMethod)
    }

    private func languageLabel(for code: String) -> String {
        LanguageOption.label(for: code, method: transcriptionMethod)
    }

    private var languageHelperText: String {
        if transcriptionMethod == .openAI {
            return "Auto detects the spoken language automatically when using OpenAI."
        } else {
            return "Choose the language you plan to speak for built-in dictation."
        }
    }
#endif

    private var settingsMenu: some View {
        Menu {
            Button {
#if os(macOS)
                openWindow(id: "files")
#else
                filesSubpanel = .list
                showingLibrarySheet = true
#endif
            } label: {
                Label("Library", systemImage: "folder")
            }

            Button {
#if os(macOS)
                openWindow(id: "settings")
#else
                showingSettings = true
#endif
            } label: {
                Label("Settings", systemImage: "gear")
            }

            if !currentTranscription.isEmpty {
                Button {
#if os(macOS)
                    openWindow(id: "transcription", value: currentTranscription)
#else
                    showingTranscription = true
#endif
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

    private func togglePlayback(for recording: RecordingFile) {
        if audioPlayer.currentRecording?.id == recording.id {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
            } else {
                audioPlayer.resume()
            }
        } else {
            Task {
                await audioPlayer.play(recording)
            }
        }
    }

    private func startRename(_ recording: RecordingFile) {
        recordingToRename = recording
        renameText = recording.fileName.replacingOccurrences(of: ".m4a", with: "")
        renameError = nil
        showingRenameAlert = true
    }

    private func performRename() {
        guard let recording = recordingToRename else { return }

        do {
            try audioRecorder.renameRecording(recording, to: renameText)
            recordingToRename = nil
            renameText = ""
            renameError = nil
            showingRenameAlert = false
        } catch {
            renameError = error.localizedDescription
        }
    }

    private func shareRecording(_ recording: RecordingFile) {
        recordingToShare = recording
        showingShareSheet = true
    }

    private func deleteRecording(_ recording: RecordingFile) {
        do {
            try FileManager.default.removeItem(at: recording.fileURL)
            audioRecorder.recordings.removeAll { $0.id == recording.id }
        } catch {
            print("Failed to delete recording: \(error.localizedDescription)")
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
#if os(macOS)
                    openWindow(id: "transcription", value: text)
#else
                    showingTranscription = true
#endif
                    quickSelectedRecordingID = recording.id
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

#if os(iOS)
private struct InputModeSelectorView: View {
    let selectedMode: AudioInputMode
    let isExternalAvailable: Bool
    let isBluetoothAvailable: Bool
    let onSelect: (AudioInputMode) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ForEach(AudioInputMode.allCases) { mode in
                let enabled = isModeEnabled(mode)
                Button {
                    if enabled {
                        onSelect(mode)
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 20, weight: .semibold))
                        Text(mode.title)
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(
                        Circle()
                            .fill(background(for: mode, enabled: enabled))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .opacity(enabled ? 1 : 0.4)
                    .scaleEffect(selectedMode == mode ? 1.05 : 1.0)
                    .shadow(color: selectedMode == mode ? Color.blue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
    }

    private func isModeEnabled(_ mode: AudioInputMode) -> Bool {
        switch mode {
        case .builtIn:
            return true
        case .external:
            return isExternalAvailable
        case .automatic:
            return true
        }
    }

    private func background(for mode: AudioInputMode, enabled: Bool) -> LinearGradient {
        if selectedMode == mode {
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            let opacity: Double = enabled ? 0.4 : 0.2
            return LinearGradient(colors: [Color.gray.opacity(opacity + 0.1), Color.gray.opacity(opacity)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
#endif

#Preview {
    ContentView()
}
