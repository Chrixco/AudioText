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
            ZStack(alignment: .bottom) {
                // Main scrollable content
                ScrollView(showsIndicators: false) {
                    ScrollViewReader { proxy in
                        recordPanel
                            .id("recordPanel")
                            .onChange(of: audioRecorder.isRecording) { _, isRecording in
                                if isRecording {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("recordPanel", anchor: .top)
                                    }
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)

                // Fixed bottom section: Recording button stacked on top of library button
                VStack(spacing: 16) {
                    // Recording button
                    NeumorphicRecordingButton(
                        isRecording: audioRecorder.isRecording,
                        action: {
                            if audioRecorder.isRecording {
                                HapticManager.shared.recordingStop()
                            } else {
                                HapticManager.shared.recordingStart()
                            }
                            toggleRecording()
                        }
                    )

                    // Library button anchored to bottom
                    libraryButton
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
                .background(
                    // Gradient fade to help the button stand out
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.background.opacity(0),
                            DesignSystem.Colors.background.opacity(0.95),
                            DesignSystem.Colors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .offset(y: -100)
                )
            }
            .navigationTitle("AudioText")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsMenu
                }
            }
            .toolbarBackground(DesignSystem.Colors.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .background(backgroundColor)
        .preferredColorScheme(.light)
#if os(iOS)
        // iOS uses fullscreen for Library/Player, sheets for Settings
        .fullScreenCover(isPresented: $showingLibrarySheet) {
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
        .fullScreenCover(isPresented: $showingTranscription) {
            TranscriptionView(transcription: currentTranscription)
        }
        .fullScreenCover(item: $panelScriptRecording) { recording in
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
        DesignSystem.Colors.background
    }

    private var recordPanel: some View {
        VStack(spacing: audioRecorder.isRecording ? 8 : 12) {
            statusBanner
#if os(iOS)
            languageInputStack
#endif
            audioVisualizerView

            if !currentTranscription.isEmpty {
                transcriptionChip
            }

            recordingHelperText

            // Add spacer to push content above the fixed bottom section
            Spacer(minLength: 240) // Height for record button + library button
        }
        .padding(.horizontal, 16)
        .padding(.top, audioRecorder.isRecording ? 4 : 8)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }

    private var statusInfo: (title: String, subtitle: String?, color: Color, icon: String) {
        if audioRecorder.isRecording {
            return ("Recording in progress", "Tap stop when you're done.", DesignSystem.Colors.recording, "record.circle")
        }

        if isProcessingTranscription {
            return ("Transcribing latest clip…", "You can keep capturing new notes.", DesignSystem.Colors.accentPurple, "waveform")
        }

        if !currentTranscription.isEmpty {
            return ("Latest transcription ready", "Preview or share it below.", DesignSystem.Colors.success, "checkmark.seal")
        }

        return ("Ready to capture audio", "Adjust input and tap the mic to begin.", DesignSystem.Colors.accentBlue, "mic.circle")
    }

    private var statusBanner: some View {
        let info = statusInfo
        return NeumorphicStatusBanner(
            icon: info.icon,
            title: info.title,
            subtitle: info.subtitle,
            color: info.color,
            isRecording: audioRecorder.isRecording
        )
    }

#if os(iOS)
    @ViewBuilder
    private var languageInputStack: some View {
        VStack(spacing: 8) {
            languageSelector
            inputModeSelector
        }
    }
#endif

    private var transcriptionChip: some View {
        Button {
            showingTranscription = true
            HapticManager.shared.buttonTap()
        } label: {
            Label("View latest transcription", systemImage: "text.bubble")
                .font(DesignSystem.Typography.bodySmall)
                .padding(.vertical, DesignSystem.Spacing.xSmall)
                .padding(.horizontal, DesignSystem.Spacing.large)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.accentBlue.opacity(0.15))
                )
                .foregroundStyle(DesignSystem.Colors.accentBlue)
        }
        .buttonStyle(.plain)
    }

    private var recordingHelperText: some View {
        let message: String
        if audioRecorder.isRecording {
            message = "Recording… tap the center button when you're finished."
        } else if isProcessingTranscription {
            message = "We're preparing the last transcript while you get ready for the next clip."
        } else {
            message = "Tap the mic to start a new note. Rotate the knob to scrub during playback."
        }

        return Text(message)
            .font(DesignSystem.Typography.bodySmall)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
    }

    private var libraryButton: some View {
        NeumorphicLibraryButton(
            recordingCount: audioRecorder.recordings.count,
            action: {
#if os(macOS)
                openWindow(id: "library")
#else
                filesSubpanel = .list
                showingLibrarySheet = true
#endif
            }
        )
    }

    private var filesListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Library", systemImage: "music.note.list")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if audioRecorder.recordings.isEmpty {
                    filesPanelEmptyState
                } else {
                    VStack(spacing: 12) {
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var filesEqualizerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 60, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("No recordings yet")
                            .font(.title3.weight(.semibold))
                        Text("Capture a clip on the Record tab to start tuning your custom equalizer profile.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
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
            VStack(spacing: 16) {
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
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
        VStack(spacing: DesignSystem.Spacing.small) {
            // Neumorphic Audio Visualizer
            if audioRecorder.isRecording {
                NeumorphicAudioVisualizer(
                    isActive: audioRecorder.isRecording,
                    levelProvider: { audioRecorder.currentLevel() }
                )

                // Recording time
                Text(formattedRecordingTime)
                    .font(DesignSystem.Typography.monoMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .monospacedDigit()
                    .padding(.top, DesignSystem.Spacing.xxSmall)
            }
        }
    }

#if os(iOS)
    private var inputModeSelector: some View {
        NeumorphicInputModeSelector(
            selectedMode: audioRecorder.inputMode,
            isExternalAvailable: audioRecorder.isExternalInputAvailable,
            isBluetoothAvailable: audioRecorder.isBluetoothAvailable,
            onSelect: { mode in audioRecorder.setInputMode(mode) }
        )
    }

    private var languageSelector: some View {
        NeumorphicLanguageSelector(
            selectedLanguageCode: $selectedLanguageCode,
            availableOptions: availableLanguageOptions
        )
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
                openWindow(id: "library")
#else
                filesSubpanel = .list
                showingLibrarySheet = true
#endif
            } label: {
                Label("Library", systemImage: "folder")
            }

            Button {
#if os(macOS)
                openWindow(id: "player")
#else
                filesSubpanel = .equalizer
                showingLibrarySheet = true
#endif
            } label: {
                Label("Player", systemImage: "play.circle")
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
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.vertical, DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: dismiss.callAsFunction)
                        .foregroundStyle(DesignSystem.Colors.accentBlue)
                }
            }
            .toolbarBackground(DesignSystem.Colors.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.light)
    }
}

#if os(iOS)
private struct InputModeSelectorView: View {
    let selectedMode: AudioInputMode
    let isExternalAvailable: Bool
    let isBluetoothAvailable: Bool
    let onSelect: (AudioInputMode) -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            ForEach(AudioInputMode.allCases) { mode in
                inputModeButton(mode: mode)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.small)
        .padding(.vertical, DesignSystem.Spacing.xSmall)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(DesignSystem.Colors.surface)
        )
    }

    @ViewBuilder
    private func inputModeButton(mode: AudioInputMode) -> some View {
        let enabled = isModeEnabled(mode)
        let isSelected = selectedMode == mode

        Button {
            if enabled {
                onSelect(mode)
                HapticManager.shared.selection()
            }
        } label: {
            VStack(spacing: DesignSystem.Spacing.xxSmall) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor(for: mode))
                Text(mode.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
            }
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(background(for: mode, enabled: enabled))
            )
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.highlightLight, lineWidth: 1)
            )
            .opacity(enabled ? 1 : 0.6)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: DesignSystem.Colors.shadowLight, radius: 8, x: -3, y: -3)
            .shadow(color: DesignSystem.Colors.shadowDark, radius: 10, x: 4, y: 4)
            .shadow(color: isSelected ? DesignSystem.Colors.accentBlue.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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
        // All buttons use background color for neumorphic effect
        return DesignSystem.Colors.buttonGradient
    }

    private func iconColor(for mode: AudioInputMode) -> Color {
        // Assign different Apple colors to each mode
        switch mode {
        case .builtIn:
            return DesignSystem.Colors.accentBlue // Blue for built-in mic
        case .external:
            return DesignSystem.Colors.accentOrange // Orange for external
        case .automatic:
            return DesignSystem.Colors.accentGreen // Green for automatic
        }
    }
}
#endif

#Preview("ContentView - Main Recording Screen") {
    ContentView()
        .environmentObject(AudioRecorder())
        .environmentObject(AudioPlayer())
        .environmentObject(SpeechRecognizer())
        .environmentObject(OpenAIService())
}
