import SwiftUI

/// Main tab bar container for iOS following Apple's Human Interface Guidelines
struct MainTabView: View {
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    @EnvironmentObject private var openAIService: OpenAIService

    @State private var selectedTab = 0
    @State private var transcriptionMethod: TranscriptionMethod = .builtIn
    @State private var selectedLanguageCode: String = "auto"
    @State private var selectedTextStyle: String = "Any changes"
    @State private var apiKey: String = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Recordings (Main Recording View)
            RecordingView(
                transcriptionMethod: $transcriptionMethod,
                selectedLanguageCode: $selectedLanguageCode,
                selectedTextStyle: $selectedTextStyle,
                apiKey: $apiKey
            )
            .tabItem {
                Label("Record", systemImage: "mic.circle.fill")
            }
            .tag(0)

            // Tab 2: Library (List of all recordings)
            LibraryView(selectedTab: $selectedTab)
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }
            .tag(1)

            // Tab 3: Player (Playback controls and equalizer)
            PlayerView()
            .tabItem {
                Label("Player", systemImage: "play.circle.fill")
            }
            .tag(2)

            // Tab 4: Settings
            SettingsView(
                transcriptionMethod: $transcriptionMethod,
                selectedLanguageCode: $selectedLanguageCode,
                selectedTextStyle: $selectedTextStyle,
                apiKey: $apiKey
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .accentColor(DesignSystem.Colors.accentBlue)
        .onChange(of: apiKey) { _, newValue in
            openAIService.setAPIKey(newValue)
        }
    }
}

// MARK: - Recording View (Main Screen)

struct RecordingView: View {
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    @EnvironmentObject private var openAIService: OpenAIService

    @Binding var transcriptionMethod: TranscriptionMethod
    @Binding var selectedLanguageCode: String
    @Binding var selectedTextStyle: String
    @Binding var apiKey: String

    @State private var currentTranscription = ""
    @State private var transcriptionErrorMessage: String?
    @State private var isProcessingTranscription = false
    @State private var lastProcessedRecordingID: UUID?
    @State private var showingTranscription = false
    @State private var showingRenameAlert = false
    @State private var recordingToRename: RecordingFile?
    @State private var renameText = ""
    @State private var renameError: String?
    @State private var showingShareSheet = false
    @State private var recordingToShare: RecordingFile?

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
                .background(DesignSystem.Colors.background)

                // Fixed bottom: Recording button only (no library button)
                VStack(spacing: 0) {
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
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showingTranscription) {
            TranscriptionWindowView(transcription: currentTranscription)
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
        .alert("Transcription Error", isPresented: transcriptionErrorBinding) {
            Button("OK", role: .cancel) {
                transcriptionErrorMessage = nil
            }
        } message: {
            if let message = transcriptionErrorMessage {
                Text(message)
            }
        }
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

            // Spacer to push content above the fixed recording button
            Spacer(minLength: 180)
        }
        .padding(.horizontal, 16)
        .padding(.top, audioRecorder.isRecording ? 4 : 8)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
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

#if os(iOS)
    @ViewBuilder
    private var languageInputStack: some View {
        VStack(spacing: 8) {
            languageSelector
            inputModeSelector
        }
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

    private var inputModeSelector: some View {
        NeumorphicInputModeSelector(
            selectedMode: audioRecorder.inputMode,
            isExternalAvailable: audioRecorder.isExternalInputAvailable,
            isBluetoothAvailable: audioRecorder.isBluetoothAvailable,
            onSelect: { mode in audioRecorder.setInputMode(mode) }
        )
    }
#endif

    private var audioVisualizerView: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            if audioRecorder.isRecording {
                NeumorphicAudioVisualizer(
                    isActive: audioRecorder.isRecording,
                    levelProvider: { audioRecorder.currentLevel() }
                )

                Text(formattedRecordingTime)
                    .font(DesignSystem.Typography.monoMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .monospacedDigit()
                    .padding(.top, DesignSystem.Spacing.xxSmall)
            }
        }
    }

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
            message = "Tap the mic to start a new note."
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

    private var formattedRecordingTime: String {
        let totalSeconds = Int(audioRecorder.recordingTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var recordingErrorBinding: Binding<Bool> {
        Binding(
            get: { audioRecorder.recordingError != nil },
            set: { if !$0 { audioRecorder.recordingError = nil } }
        )
    }

    private var transcriptionErrorBinding: Binding<Bool> {
        Binding(
            get: { transcriptionErrorMessage != nil },
            set: { if !$0 { transcriptionErrorMessage = nil } }
        )
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            if let recording = audioRecorder.stopRecording() {
                processTranscription(for: recording)
            }
        } else {
            Task {
                await audioRecorder.startRecording()
            }
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

            let language = selectedLanguageCode.isEmpty || selectedLanguageCode == "auto" ? "auto" : selectedLanguageCode

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
                    // Don't show transcription automatically - user can view it from Library
                }
            } catch {
                Task { @MainActor in
                    transcriptionErrorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Library View

struct LibraryView: View {
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @Environment(\.editMode) private var editMode
    @Binding var selectedTab: Int // To switch to player tab

    @State private var selectedRecordings: Set<UUID> = []
    @State private var showingRenameAlert = false
    @State private var recordingToRename: RecordingFile?
    @State private var renameText = ""
    @State private var showingShareSheet = false
    @State private var recordingsToShare: [RecordingFile] = []
    @State private var showingDeleteAlert = false
    @State private var selectedRecordingForDetail: RecordingFile? = nil

    var body: some View {
        NavigationStack {
            if audioRecorder.recordings.isEmpty {
                emptyStateView
            } else {
                List(selection: $selectedRecordings) {
                    ForEach(audioRecorder.recordings) { recording in
                        RecordingRowView(
                            recording: recording,
                            isPlaying: audioPlayer.currentRecording?.id == recording.id && audioPlayer.isPlaying,
                            onPlayTap: {
                                playRecording(recording)
                            },
                            onTranscriptTap: {
                                selectedRecordingForDetail = recording
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteRecording(recording)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                shareRecordings([recording])
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                renameRecording(recording)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, editMode)
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !audioRecorder.recordings.isEmpty {
                    EditButton()
                }
            }

            if editMode?.wrappedValue.isEditing == true && !selectedRecordings.isEmpty {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        shareSelectedRecordings()
                    } label: {
                        Label("Share (\(selectedRecordings.count))", systemImage: "square.and.arrow.up")
                    }

                    Spacer()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete (\(selectedRecordings.count))", systemImage: "trash")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: recordingsToShare.map { $0.fileURL })
        }
        .sheet(item: $selectedRecordingForDetail) { recording in
            RecordingDetailView(recording: recording, selectedTab: $selectedTab)
                .environmentObject(audioPlayer)
                .environmentObject(audioRecorder)
        }
        .alert("Rename Recording", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                recordingToRename = nil
                renameText = ""
            }
            Button("Rename") {
                performRename()
            }
        } message: {
            Text("Enter a new name for the recording")
        }
        .alert("Delete \(selectedRecordings.count) Recording\(selectedRecordings.count > 1 ? "s" : "")?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSelectedRecordings()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Recordings Yet")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Start recording from the Record tab")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }

    private func playRecording(_ recording: RecordingFile) {
        if audioPlayer.currentRecording?.id == recording.id && audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            Task {
                await audioPlayer.play(recording)
            }
            // Switch to Player tab to show the player interface
            selectedTab = 2
        }
        HapticManager.shared.selection()
    }

    private func deleteRecording(_ recording: RecordingFile) {
        audioRecorder.deleteRecording(recording)
        HapticManager.shared.light()
    }

    private func deleteSelectedRecordings() {
        let recordingsToDelete = audioRecorder.recordings.filter { selectedRecordings.contains($0.id) }
        recordingsToDelete.forEach { audioRecorder.deleteRecording($0) }
        selectedRecordings.removeAll()
        editMode?.wrappedValue = .inactive
        HapticManager.shared.success()
    }

    private func shareRecordings(_ recordings: [RecordingFile]) {
        recordingsToShare = recordings
        showingShareSheet = true
        HapticManager.shared.light()
    }

    private func shareSelectedRecordings() {
        let recordings = audioRecorder.recordings.filter { selectedRecordings.contains($0.id) }
        shareRecordings(recordings)
    }

    private func renameRecording(_ recording: RecordingFile) {
        recordingToRename = recording
        renameText = recording.fileName
        showingRenameAlert = true
        HapticManager.shared.light()
    }

    private func performRename() {
        guard let _ = recordingToRename, !renameText.isEmpty else { return }
        // TODO: Implement rename functionality in AudioRecorder
        // audioRecorder.renameRecording(recording, to: renameText)
        recordingToRename = nil
        renameText = ""
        HapticManager.shared.success()
    }
}

// MARK: - Recording Row View

private struct RecordingRowView: View {
    let recording: RecordingFile
    var isPlaying: Bool = false
    var onPlayTap: (() -> Void)? = nil
    var onTranscriptTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Recording info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.fileName)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(isPlaying ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(recording.dateCreated, style: .date)
                    Text("•")
                    Text(recording.dateCreated, style: .time)
                    Text("•")
                    Text(formatDuration(recording.duration))
                }
                .font(DesignSystem.Typography.captionMedium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 8) {
                // Show Transcript button
                if recording.transcript != nil {
                    Button(action: {
                        onTranscriptTap?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Transcript")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(DesignSystem.Colors.accentPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous)
                                .fill(DesignSystem.Colors.surface)
                                .shadow(color: DesignSystem.Colors.shadowDark.opacity(0.15), radius: 2, x: 1, y: 1)
                                .shadow(color: DesignSystem.Colors.shadowLight, radius: 2, x: -1, y: -1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Play/Pause button
                Button(action: {
                    onPlayTap?()
                }) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: DesignSystem.Colors.shadowDark.opacity(0.2), radius: 4, x: 2, y: 2)
                            .shadow(color: DesignSystem.Colors.shadowLight, radius: 4, x: -2, y: -2)

                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isPlaying ? .white : DesignSystem.Colors.accentBlue)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Recording Detail View

private struct RecordingDetailView: View {
    let recording: RecordingFile
    @Binding var selectedTab: Int
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @Environment(\.dismiss) private var dismiss

    private var isPlaying: Bool {
        audioPlayer.currentRecording?.id == recording.id && audioPlayer.isPlaying
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recording Info Card
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Colors.accentBlue)

                        Text(recording.fileName)
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        HStack(spacing: 16) {
                            Label(formatDuration(recording.duration), systemImage: "clock")
                            Label(recording.formattedFileSize, systemImage: "doc")
                        }
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                        Text(recording.dateCreated, style: .date)
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                            .fill(DesignSystem.Colors.surface)
                            .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
                    )

                    // Play Button
                    Button(action: {
                        togglePlayback()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text(isPlaying ? "Pause" : "Play Recording")
                                .font(DesignSystem.Typography.bodyLarge)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                                .fill(DesignSystem.Colors.accentBlue)
                                .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
                        )
                    }
                    .buttonStyle(.plain)

                    // Transcript Section
                    if let transcript = recording.transcript {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(DesignSystem.Colors.accentPurple)
                                Text("Transcript")
                                    .font(DesignSystem.Typography.titleSmall)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                Spacer()
                            }

                            Text(transcript)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .textSelection(.enabled)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                                        .fill(DesignSystem.Colors.background)
                                        .applyShadows(DesignSystem.NeumorphicShadow.mediumDebossed())
                                )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                .fill(DesignSystem.Colors.surface)
                                .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
                        )
                    } else {
                        // No transcript available
                        VStack(spacing: 12) {
                            Image(systemName: "text.badge.xmark")
                                .font(.system(size: 40))
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                            Text("No Transcript Available")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Text("Transcription was not performed for this recording")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                .fill(DesignSystem.Colors.surface)
                                .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
                        )
                    }
                }
                .padding(20)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func togglePlayback() {
        if audioPlayer.currentRecording?.id == recording.id {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
            } else {
                audioPlayer.resume()
                // Switch to Player tab when resuming
                selectedTab = 2
                dismiss()
            }
        } else {
            Task {
                await audioPlayer.play(recording)
            }
            // Switch to Player tab when starting new playback
            selectedTab = 2
            dismiss()
        }
        HapticManager.shared.selection()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Player View

struct PlayerView: View {
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @EnvironmentObject private var audioRecorder: AudioRecorder

    @State private var selectedRecordingID: UUID?
    @State private var showingEqualizer = false
    @State private var knobProgress: Double = 0

    private var selectedRecording: RecordingFile? {
        if let id = selectedRecordingID {
            return audioRecorder.recordings.first { $0.id == id }
        }
        // Auto-select currently playing or first recording
        return audioPlayer.currentRecording ?? audioRecorder.recordings.first
    }

    var body: some View {
        NavigationStack {
            if audioRecorder.recordings.isEmpty {
                emptyStateView
            } else if let recording = selectedRecording {
                ScrollView {
                    VStack(spacing: 24) {
                        // Recording Selector
                        recordingSelector

                        // Rotary Play Button
                        rotaryPlayButton(for: recording)

                        // Time Display
                        timeDisplay

                        // Waveform Timeline
                        waveformSection(for: recording)

                        // Playback Controls
                        playbackControls

                        // Equalizer Section (Collapsible)
                        equalizerSection(for: recording)

                        // Export/Share Section
                        exportSection(for: recording)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .background(DesignSystem.Colors.background)
            }
        }
        .navigationTitle("Player")
        .onAppear {
            refreshSelection()
        }
        .onChange(of: audioRecorder.recordings) { _, _ in
            refreshSelection()
        }
        .onChange(of: audioPlayer.currentRecording) { _, newRecording in
            if let recording = newRecording {
                selectedRecordingID = recording.id
            }
        }
        .onChange(of: audioPlayer.progress) { _, newProgress in
            // Sync knob with player progress (only when not dragging)
            knobProgress = newProgress
        }
    }

    // MARK: - Recording Selector

    private var recordingSelector: some View {
        Menu {
            ForEach(audioRecorder.recordings) { recording in
                Button {
                    selectedRecordingID = recording.id
                    // Load the selected recording if not already playing
                    if audioPlayer.currentRecording?.id != recording.id {
                        Task {
                            await audioPlayer.play(recording)
                            audioPlayer.pause()  // Pause after loading
                        }
                    }
                } label: {
                    HStack {
                        Text(recording.fileName)
                        if recording.id == selectedRecordingID {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.accentBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedRecording?.fileName ?? "Select Recording")
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    Text(selectedRecording?.formattedDate ?? "")
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(DesignSystem.Colors.surface)
                    .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
            )
        }
    }

    // MARK: - Rotary Play Button

    private func rotaryPlayButton(for recording: RecordingFile) -> some View {
        let isCurrentlyPlaying = audioPlayer.currentRecording?.id == recording.id && audioPlayer.isPlaying

        return NeumorphicRotaryPlayButton(
            progress: $knobProgress,
            isPlaying: isCurrentlyPlaying,
            onPlayPause: {
                togglePlayback(for: recording)
            },
            onScrub: { newProgress in
                scrubToProgress(newProgress, for: recording)
            },
            centerTitle: audioPlayer.formattedCurrentTime,
            centerSubtitle: audioPlayer.formattedDuration
        )
        .padding(.vertical, 8)
    }

    // MARK: - Time Display

    private var timeDisplay: some View {
        HStack(spacing: 12) {
            Text(audioPlayer.formattedCurrentTime)
                .font(DesignSystem.Typography.monoMedium)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text(audioPlayer.formattedDuration)
                .font(DesignSystem.Typography.monoMedium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                .fill(DesignSystem.Colors.background)
                .applyShadows(DesignSystem.NeumorphicShadow.mediumDebossed())
        )
    }

    // MARK: - Waveform Section

    private func waveformSection(for recording: RecordingFile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waveform")
                .font(DesignSystem.Typography.captionLarge)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 4)

            WaveformTimeline(
                recording: recording,
                progress: audioPlayer.progress,
                isPlaying: audioPlayer.currentRecording?.id == recording.id && audioPlayer.isPlaying,
                onSeek: { progress in
                    scrubToProgress(progress, for: recording)
                }
            )
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        NeumorphicPlaybackControls(
            onSkipBackward: {
                skipBackward()
            },
            onSkipForward: {
                skipForward()
            },
            playbackRate: audioPlayer.playbackRate,
            onRateChange: { rate in
                audioPlayer.setPlaybackRate(rate)
            }
        )
    }

    // MARK: - Equalizer Section

    private func equalizerSection(for recording: RecordingFile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showingEqualizer.toggle()
                }
                HapticManager.shared.selection()
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Equalizer")
                        .font(DesignSystem.Typography.titleSmall)
                    Spacer()
                    Image(systemName: showingEqualizer ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                        .fill(DesignSystem.Colors.surface)
                        .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
                )
            }
            .buttonStyle(.plain)

            if showingEqualizer {
                EqualizerPanel(
                    recording: recording,
                    settings: audioRecorder.equalizerSettings(for: recording),
                    onSave: { settings in
                        audioRecorder.updateEqualizerSettings(settings, for: recording)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Export Section

    private func exportSection(for recording: RecordingFile) -> some View {
        HStack(spacing: 12) {
            Button {
                // Share recording
                HapticManager.shared.selection()
                // TODO: Implement share sheet
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Share")
                        .font(DesignSystem.Typography.bodyMedium)
                        .fontWeight(.medium)
                }
                .foregroundStyle(DesignSystem.Colors.accentBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                        .fill(DesignSystem.Colors.surface)
                        .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
                )
            }
            .buttonStyle(.plain)

            Button {
                // Export recording
                HapticManager.shared.selection()
                // TODO: Implement export
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Export")
                        .font(DesignSystem.Typography.bodyMedium)
                        .fontWeight(.medium)
                }
                .foregroundStyle(DesignSystem.Colors.accentBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                        .fill(DesignSystem.Colors.surface)
                        .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Recordings")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Record audio from the Recordings tab")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Helper Functions

    private func refreshSelection() {
        if let id = selectedRecordingID,
           audioRecorder.recordings.contains(where: { $0.id == id }) {
            return
        }
        selectedRecordingID = audioPlayer.currentRecording?.id ?? audioRecorder.recordings.first?.id
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

    private func scrubToProgress(_ progress: Double, for recording: RecordingFile) {
        // Ensure recording is loaded
        if audioPlayer.currentRecording?.id != recording.id {
            Task {
                await audioPlayer.play(recording)
                audioPlayer.pause()
                let targetTime = progress * audioPlayer.duration
                audioPlayer.seek(to: targetTime)
            }
        } else {
            let targetTime = progress * audioPlayer.duration
            audioPlayer.seek(to: targetTime)
        }
    }

    private func skipBackward() {
        let newTime = max(0, audioPlayer.currentTime - 15)
        audioPlayer.seek(to: newTime)
    }

    private func skipForward() {
        let newTime = min(audioPlayer.duration, audioPlayer.currentTime + 15)
        audioPlayer.seek(to: newTime)
    }
}

// MARK: - Equalizer Panel

private struct EqualizerPanel: View {
    let recording: RecordingFile
    @State var settings: EqualizerSettings
    let onSave: (EqualizerSettings) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EqualizerPreset.allCases) { preset in
                        Button {
                            settings = preset.settings
                            onSave(settings)
                            HapticManager.shared.selection()
                        } label: {
                            Text(preset.title)
                                .font(.caption.weight(.medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            preset.settings == settings
                                                ? DesignSystem.Colors.accentBlue.opacity(0.2)
                                                : DesignSystem.Colors.surface
                                        )
                                        .applyShadows(
                                            preset.settings == settings
                                                ? DesignSystem.NeumorphicShadow.smallEmbossed()
                                                : []
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // EQ sliders
            HStack(alignment: .top, spacing: 12) {
                ForEach(EqualizerBand.allCases) { band in
                    EqualizerBandControl(
                        band: band,
                        value: Binding(
                            get: { settings.value(for: band) },
                            set: { newValue in
                                settings.setValue(newValue, for: band)
                                onSave(settings)
                            }
                        )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                .fill(DesignSystem.Colors.surface)
                .applyShadows(DesignSystem.NeumorphicShadow.mediumDebossed())
        )
    }
}

// MARK: - Preview

#Preview("Main Tab View") {
    MainTabView()
        .environmentObject(AudioRecorder())
        .environmentObject(AudioPlayer())
        .environmentObject(SpeechRecognizer())
        .environmentObject(OpenAIService())
}
