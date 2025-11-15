import SwiftUI

struct FilesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var audioPlayer: AudioPlayer

    @State private var selectedRecording: RecordingFile?
    @State private var showingScript = false
    @State private var showingRenameAlert = false
    @State private var recordingToRename: RecordingFile?
    @State private var renameText = ""
    @State private var renameError: String?
    @State private var showingShareSheet = false
    @State private var recordingToShare: RecordingFile?

    var body: some View {
        NavigationStack {
            content
        }
        .onAppear(perform: ensureSelection)
        .onChange(of: audioRecorder.recordings) { _, _ in
            ensureSelection()
        }
        .sheet(isPresented: $showingScript) {
            if let transcript = selectedRecording?.transcript, !transcript.isEmpty {
                TranscriptionView(transcription: transcript)
            } else {
                TranscriptionView(transcription: "No transcript is available for this recording yet.")
            }
        }
        .alert("Rename Recording", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renameError = nil
            }
            Button("Rename") {
                performRename()
            }
        } message: {
            if let error = renameError {
                Text(error)
            } else {
                Text("Enter a new name for this recording")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let recording = recordingToShare {
                ShareSheet(items: [recording.fileURL])
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if audioRecorder.recordings.isEmpty {
                emptyState
            } else {
                recordingsList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
#if os(iOS)
        .background(DesignSystem.Colors.background)
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done", action: dismiss.callAsFunction)
            }
        }
#else
        .background(DesignSystem.Colors.background)
        .frame(minWidth: 900, minHeight: 620)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close", action: dismiss.callAsFunction)
            }
        }
#endif
    }

    private var recordingsList: some View {
        List {
            if let recording = selectedRecording {
                Section {
                    RecordingDetailCard(
                        recording: recording,
                        showingScript: $showingScript,
                        togglePlayback: { togglePlayback(for: recording) },
                        equalizerSettings: audioRecorder.equalizerSettings(for: recording),
                        onSaveEqualizer: { settings in
                            audioRecorder.updateEqualizerSettings(settings, for: recording)
                        }
                    )
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            }

            Section("All Recordings") {
                ForEach(audioRecorder.recordings) { recording in
                    RecordingListRow(
                        recording: recording,
                        isSelected: recording.id == selectedRecording?.id,
                        equalizerSettings: audioRecorder.equalizerSettings(for: recording),
                        onPlayTapped: {
                            select(recording)
                            togglePlayback(for: recording)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        select(recording)
                    }
#if os(iOS)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteRecording(recording)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            startRename(recording)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.blue)
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
#else
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
#endif
                }
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.inset)
#endif
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Recordings Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Start a new recording from the main screen. Your clips, audio levels, and scripts will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    private func timeLabel(for recording: RecordingFile) -> String {
        if isSelectedRecordingPlaying(recording) {
            return "\(audioPlayer.formattedCurrentTime) • \(audioPlayer.formattedDuration)"
        } else {
            return recording.formattedDuration
        }
    }

    private func playbackGradient(for recording: RecordingFile) -> LinearGradient {
        if isPlayingSelected(recording) {
            return LinearGradient(colors: [DesignSystem.Colors.recording, DesignSystem.Colors.accentOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return DesignSystem.Colors.accentGradient
        }
    }

    private func togglePlayback(for recording: RecordingFile) {
        if isSelectedRecordingPlaying(recording) {
            audioPlayer.pause()
        } else if audioPlayer.currentRecording?.id == recording.id {
            audioPlayer.resume()
        } else {
            Task {
                await audioPlayer.play(recording)
            }
        }
    }

    private func select(_ recording: RecordingFile) {
        selectedRecording = recording
    }

    private func deleteRecording(_ recording: RecordingFile) {
        audioRecorder.deleteRecording(recording)
        if selectedRecording?.id == recording.id {
            selectedRecording = audioRecorder.recordings.first
        }
    }

    private func startRename(_ recording: RecordingFile) {
        recordingToRename = recording
        // Pre-fill with current name without extension
        let nameWithoutExtension = recording.fileName.replacingOccurrences(of: ".m4a", with: "")
        renameText = nameWithoutExtension
        renameError = nil
        showingRenameAlert = true
    }

    private func performRename() {
        guard let recording = recordingToRename else { return }

        do {
            try audioRecorder.renameRecording(recording, to: renameText)
            renameError = nil
            showingRenameAlert = false

            // Update selected recording if it was renamed
            if selectedRecording?.id == recording.id {
                selectedRecording = audioRecorder.recordings.first { $0.id == recording.id }
            }
        } catch {
            renameError = error.localizedDescription
            // Keep alert open to show error
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingRenameAlert = true
            }
        }
    }

    private func shareRecording(_ recording: RecordingFile) {
        recordingToShare = recording
        showingShareSheet = true
    }

    private func ensureSelection() {
        if let current = selectedRecording, audioRecorder.recordings.contains(where: { $0.id == current.id }) {
            return
        }
        selectedRecording = audioRecorder.recordings.first
    }

    private func isPlayingSelected(_ recording: RecordingFile) -> Bool {
        audioPlayer.currentRecording?.id == recording.id && audioPlayer.isPlaying
    }

    private func isSelectedRecordingPlaying(_ recording: RecordingFile) -> Bool {
        recording.id == selectedRecording?.id && isPlayingSelected(recording)
    }
}

struct RecordingDetailCard: View {
    @EnvironmentObject private var audioPlayer: AudioPlayer

    let recording: RecordingFile
    @Binding var showingScript: Bool
    let togglePlayback: () -> Void
    let equalizerSettings: EqualizerSettings
    let onSaveEqualizer: (EqualizerSettings) -> Void

    @State private var knobValue: Double = 0
    @State private var isEditing = false
    @State private var isScrubbingFromTimeline = false
    @State private var workingEqualizer: EqualizerSettings
    @State private var shareItems: [Any] = []
    @State private var isSharing = false
    @State private var isExporting = false
    @State private var exportErrorMessage: String?

    // NEW: Neumorphic equalizer settings
    @State private var newEqualizerSettings = NeumorphicEqualizerSettings()

    init(
        recording: RecordingFile,
        showingScript: Binding<Bool>,
        togglePlayback: @escaping () -> Void,
        equalizerSettings: EqualizerSettings,
        onSaveEqualizer: @escaping (EqualizerSettings) -> Void
    ) {
        self.recording = recording
        _showingScript = showingScript
        self.togglePlayback = togglePlayback
        self.equalizerSettings = equalizerSettings
        self.onSaveEqualizer = onSaveEqualizer
        _workingEqualizer = State(initialValue: equalizerSettings)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Waveform Timeline
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Timeline")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text("Tap or drag to scrub")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 4)

                    WaveformTimeline(
                        recording: recording,
                        progress: knobValue,
                        isPlaying: isCurrentlyPlaying,
                        onSeek: { position in
                            isScrubbingFromTimeline = true
                            knobValue = position
                            if audioPlayer.duration > 0 {
                                audioPlayer.seek(to: position * audioPlayer.duration)
                            }
                            // Reset flag after a short delay to allow the knob to sync
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                isScrubbingFromTimeline = false
                            }
                        }
                    )
                }

                // Live Audio Visualizer
                VStack(alignment: .leading, spacing: 6) {
                    Text("Live Level")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    AudioVisualizer(
                        isActive: isCurrentlyPlaying,
                        levelProvider: { audioPlayer.currentLevel() }
                    )
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                            .fill(DesignSystem.Colors.surface)
                            .shadow(color: DesignSystem.Colors.shadowDark.opacity(0.2), radius: 4, x: 2, y: 2)
                            .shadow(color: DesignSystem.Colors.highlightLight, radius: 4, x: -2, y: -2)
                    )
                }

                // Rotary Knob
                RotaryKnob(
                    value: $knobValue,
                    isActive: isCurrentlyPlaying,
                    onEditingChanged: { editing in
                        isEditing = editing
                        if editing {
                            audioPlayer.beginInteractiveScrub(for: recording)
                        } else {
                            audioPlayer.endInteractiveScrub()
                            syncKnobWithPlayer()
                        }
                    },
                    onTap: togglePlayback,
                    centerIcon: isCurrentlyPlaying ? "pause.fill" : "play.fill",
                    centerTitle: isCurrentlyPlaying ? "Pause" : "Play",
                    centerSubtitle: timeLabel,
                    onScrubDelta: handleScrubDelta
                )
                .frame(width: 200, height: 200)
                .onAppear(perform: syncKnobWithPlayer)
                .onChange(of: audioPlayer.currentTime) { _ in
                    guard !isEditing, !isScrubbingFromTimeline, isTrackingCurrentRecording, audioPlayer.duration > 0 else { return }
                    knobValue = audioPlayer.progress
                }
                .onChange(of: audioPlayer.currentRecording?.id) { _ in
                    syncKnobWithPlayer()
                }

                // Recording info
                VStack(spacing: 6) {
                    Text(cleanRecordingName)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(timeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Action buttons
                VStack(spacing: 12) {
                    scriptControl
                    exportControls
                }

                Divider()
                    .padding(.vertical, 8)

                // Equalizer Section
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Equalizer")
                            .font(.title3.weight(.semibold))
                            .padding(.horizontal, 4)
                        Text("Adjust five-band EQ in two panels, then save to this recording.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }

                    // Two-panel layout with 3 bars each
                    VStack(spacing: 20) {
                        // Panel 1: Low, Low-Mid, Mid frequencies
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Low & Mid Frequencies")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            HStack(alignment: .bottom, spacing: 20) {
                                ForEach([EqualizerBand.lowShelf, EqualizerBand.bass, EqualizerBand.mid], id: \.self) { band in
                                    EqualizerBandControl(
                                        band: band,
                                        value: binding(for: band)
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(DesignSystem.Colors.surface.opacity(0.5))
                        )

                        // Panel 2: High-Mid, High frequencies
                        VStack(alignment: .leading, spacing: 10) {
                            Text("High Frequencies")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            HStack(alignment: .bottom, spacing: 20) {
                                ForEach([EqualizerBand.presence, EqualizerBand.air], id: \.self) { band in
                                    EqualizerBandControl(
                                        band: band,
                                        value: binding(for: band)
                                    )
                                }
                                // Spacer to balance the layout
                                Spacer()
                                    .frame(width: 80)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(DesignSystem.Colors.surface.opacity(0.5))
                        )
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Output Gain")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 4)
                        EqualizerBandControl(
                            band: .preGain,
                            value: binding(for: .preGain)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    presetsSection

                    VStack(spacing: 10) {
                        if isEqualizerDirty {
                            Text("Unsaved changes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Saved profile: \(equalizerSettings.formattedSummary())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 10) {
                            Button("Reset to Flat") {
                                workingEqualizer = .flat
                            }
                            .buttonStyle(.bordered)

                            Button {
                                saveEqualizer()
                            } label: {
                                Label("Save Settings", systemImage: "square.and.arrow.down")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!isEqualizerDirty)
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 20)

                // NEW NEUMORPHIC EQUALIZER (Built from scratch!)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NEW: Neumorphic Equalizer")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(DesignSystem.Colors.accentBlue)

                            Text("Built from scratch with SwiftUI • Swipeable panels")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignSystem.Colors.accentCyan)
                    }
                    .padding(.horizontal, 4)

                    NeumorphicEqualizerPanel(settings: $newEqualizerSettings)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .onChange(of: equalizerSettings) { newValue in
            if newValue != workingEqualizer {
                workingEqualizer = newValue
            }
        }
        .onChange(of: recording.id) { _ in
            workingEqualizer = equalizerSettings
            syncKnobWithPlayer()
        }
    }

    private var isCurrentlyPlaying: Bool {
        audioPlayer.currentRecording?.id == recording.id && audioPlayer.isPlaying
    }

    private var isTrackingCurrentRecording: Bool {
        audioPlayer.currentRecording?.id == recording.id
    }

    private var timeLabel: String {
        if isCurrentlyPlaying {
            return "\(audioPlayer.formattedCurrentTime) • \(audioPlayer.formattedDuration)"
        } else {
            return recording.formattedDuration
        }
    }

    private var scriptControl: some View {
        Group {
            if let transcript = recording.transcript, !transcript.isEmpty {
                Button {
                    showingScript = true
                } label: {
                    Label("Show Script", systemImage: "text.quote")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                                .fill(DesignSystem.Colors.surface)
                                .shadow(color: DesignSystem.Colors.highlightLight, radius: 3, x: -2, y: -2)
                                .shadow(color: DesignSystem.Colors.shadowDark, radius: 4, x: 2, y: 2)
                        )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
                    Label("Transcript pending", systemImage: "hourglass")
                        .font(.headline)
                    Text("Recordings transcribe automatically after you stop recording. Once ready, you can review the full script here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                        .fill(DesignSystem.Colors.surface.opacity(0.5))
                        .shadow(color: DesignSystem.Colors.shadowDark.opacity(0.15), radius: 2, x: 1, y: 1)
                        .shadow(color: DesignSystem.Colors.highlightLight.opacity(0.5), radius: 2, x: -1, y: -1)
                )
            }
        }
    }

    private var exportControls: some View {
        Group {
            if let transcript = recording.transcript, !transcript.isEmpty {
                VStack(spacing: 12) {
                    if isExporting {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Preparing export…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Menu {
                        Button {
                            triggerExport(format: .pdf, transcript: transcript)
                        } label: {
                            Label("Share as PDF", systemImage: "doc.richtext")
                        }

                        Button {
                            triggerExport(format: .word, transcript: transcript)
                        } label: {
                            Label("Share as Word (RTF)", systemImage: "doc")
                        }
                    } label: {
                        Label("Export / Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous)
                                    .fill(DesignSystem.Colors.surface)
                                    .shadow(color: DesignSystem.Colors.highlightLight, radius: 3, x: -2, y: -2)
                                    .shadow(color: DesignSystem.Colors.shadowDark, radius: 4, x: 2, y: 2)
                            )
                    }
                    .disabled(isExporting)
                }
            }
        }
#if os(iOS)
        .sheet(isPresented: $isSharing) {
            ShareSheet(items: shareItems)
        }
#else
        .background(ShareSheet(items: shareItems))
#endif
        .alert("Export Failed", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { newValue in
                if !newValue { exportErrorMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "Unknown error")
        }
    }

    private func syncKnobWithPlayer() {
        guard isTrackingCurrentRecording, audioPlayer.duration > 0 else {
            knobValue = 0
            return
        }
        knobValue = audioPlayer.progress
    }

    private func handleScrubDelta(deltaValue: Double, interval: TimeInterval, ended: Bool) {
        guard isEditing, !ended, audioPlayer.duration > 0 else { return }
        let velocity = interval > 0 ? deltaValue / interval : 0
        audioPlayer.updateInteractiveScrub(progress: knobValue, velocity: velocity)
    }

    private var tonalBands: [EqualizerBand] {
        EqualizerBand.allCases.filter { $0 != .preGain }
    }

    private var isEqualizerDirty: Bool {
        workingEqualizer != equalizerSettings
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EqualizerPreset.allCases) { preset in
                        Button {
                            workingEqualizer = preset.settings
                        } label: {
                            Text(preset.title)
                                .font(.caption.weight(.medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(preset.settings == workingEqualizer ? DesignSystem.Colors.accentBlue.opacity(0.2) : DesignSystem.Colors.surface)
                                        .shadow(color: DesignSystem.Colors.shadowDark.opacity(0.2), radius: 2, x: 1, y: 1)
                                        .shadow(color: DesignSystem.Colors.highlightLight, radius: 2, x: -1, y: -1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func binding(for band: EqualizerBand) -> Binding<Double> {
        Binding(
            get: { workingEqualizer.value(for: band) },
            set: { newValue in
                workingEqualizer.setValue(newValue, for: band)
            }
        )
    }

    private func saveEqualizer() {
        let snapshot = workingEqualizer
        onSaveEqualizer(snapshot)
    }

    private var cleanRecordingName: String {
        let name = recording.fileName
        if let dotIndex = name.lastIndex(of: ".") {
            return String(name[..<dotIndex])
        }
        return name
    }

    private func triggerExport(format: ExportManager.Format, transcript: String) {
        guard !isExporting else { return }
        isExporting = true

        Task {
            do {
                let url = try ExportManager.export(recording: recording, transcript: transcript, format: format)
                await MainActor.run {
                    shareItems = [url]
                    isSharing = true
                }
            } catch {
                await MainActor.run {
                    exportErrorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isExporting = false
            }
        }
    }
}

struct EqualizerBandControl: View {
    let band: EqualizerBand
    @Binding var value: Double

    @State private var isDragging = false
    private let haptics = HapticManager.shared

    private let barWidth: CGFloat = 80  // Larger for two-panel layout (3 bars each)
    private let barHeight: CGFloat = 240  // Taller for better control range

    var body: some View {
        VStack(spacing: 8) {
            Text(formattedValue)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(isDragging ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.2), value: isDragging)

            GeometryReader { proxy in
                let height = proxy.size.height
                let centerY = height * 0.5  // Center position for 0dB

                ZStack(alignment: .bottom) {
                    // Background debossed container
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control + 2, style: .continuous)
                        .fill(DesignSystem.Colors.background)
                        .shadow(color: DesignSystem.Colors.shadowDark, radius: isDragging ? 12 : 10, x: isDragging ? 5 : 4, y: isDragging ? 5 : 4)
                        .shadow(color: DesignSystem.Colors.shadowLight, radius: isDragging ? 10 : 8, x: isDragging ? -4 : -3, y: isDragging ? -4 : -3)
                        .animation(.easeInOut(duration: 0.15), value: isDragging)

                    // Center line indicator (0dB reference)
                    Rectangle()
                        .fill(DesignSystem.Colors.textTertiary.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -centerY)

                    // Active fill gradient
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                        .fill(fillGradient)
                        .frame(height: max(6, min(height, height * normalizedValue)))
                        .shadow(color: gradientColor.opacity(0.4), radius: isDragging ? 6 : 3, x: 0, y: 0)
                        .animation(.easeInOut(duration: 0.15), value: isDragging)

                    // Glow effect when dragging
                    if isDragging {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                            .fill(gradientColor.opacity(0.2))
                            .frame(height: max(6, min(height, height * normalizedValue)))
                            .blur(radius: 8)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                if #available(iOS 13.0, *) {
                                    haptics.soft()
                                }
                            }

                            let clampedY = min(max(0, gesture.location.y), height)
                            let ratio = 1 - (clampedY / height)
                            let range = band.gainRange
                            let mapped = range.lowerBound + Double(ratio) * (range.upperBound - range.lowerBound)
                            let step = max(band.step, 0.1)
                            let quantized = (mapped / step).rounded() * step
                            let clampedValue = min(max(quantized, range.lowerBound), range.upperBound)

                            // Reduced haptic feedback - only every 2 steps
                            if abs(clampedValue - value) >= step * 2 {
                                if #available(iOS 13.0, *) {
                                    haptics.soft()
                                }
                            }

                            value = clampedValue
                        }
                        .onEnded { _ in
                            isDragging = false
                            haptics.light()
                        }
                )
            }
            .frame(width: barWidth, height: barHeight)

            VStack(spacing: 2) {
                Text(band.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isDragging ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(band.frequencyLabel)
                    .font(.caption2)
                    .foregroundStyle(isDragging ? DesignSystem.Colors.accentBlue.opacity(0.7) : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
        }
        .frame(width: barWidth + 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(band.title) band")
        .accessibilityValue(formattedValue)
        .accessibilityHint("Adjust to change the \(band.title.lowercased()) gain")
        .accessibilityAdjustableAction { direction in
            let step = band.step
            let range = band.gainRange
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
                haptics.light()
            case .decrement:
                value = max(value - step, range.lowerBound)
                haptics.light()
            default:
                break
            }
        }
    }

    private var normalizedValue: CGFloat {
        let range = band.gainRange
        guard range.upperBound > range.lowerBound else { return 0.5 }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return CGFloat((clamped - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private var formattedValue: String {
        String(format: "%+.1f dB", value)
    }

    // Dynamic gradient based on value (boost vs cut)
    private var fillGradient: LinearGradient {
        let range = band.gainRange
        let isBoost = value > 0
        let isCut = value < 0
        let intensity = abs(value) / max(abs(range.upperBound), abs(range.lowerBound))

        if isBoost {
            // Green to yellow gradient for boost
            return LinearGradient(
                colors: [
                    DesignSystem.Colors.accentGreen.opacity(0.4 + Double(intensity) * 0.4),
                    DesignSystem.Colors.accentGreen.opacity(0.6 + Double(intensity) * 0.3)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        } else if isCut {
            // Blue gradient for cut
            return LinearGradient(
                colors: [
                    DesignSystem.Colors.accentBlue.opacity(0.4 + Double(intensity) * 0.4),
                    DesignSystem.Colors.accentBlue.opacity(0.6 + Double(intensity) * 0.3)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        } else {
            // Neutral gray for 0dB
            return LinearGradient(
                colors: [
                    DesignSystem.Colors.textSecondary.opacity(0.3),
                    DesignSystem.Colors.textSecondary.opacity(0.4)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    // Color for glow and shadow effects
    private var gradientColor: Color {
        let isBoost = value > 0
        let isCut = value < 0

        if isBoost {
            return DesignSystem.Colors.accentGreen
        } else if isCut {
            return DesignSystem.Colors.accentBlue
        } else {
            return DesignSystem.Colors.textSecondary
        }
    }
}

struct RecordingListRow: View {
    let recording: RecordingFile
    let isSelected: Bool
    let equalizerSettings: EqualizerSettings
    var onPlayTapped: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recording.fileName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                if let onPlayTapped {
                    Button(action: onPlayTapped) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                Text(recording.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                    Label(recording.formattedDate, systemImage: "calendar")
                Label(recording.formattedFileSize, systemImage: "tray")
            }
            .labelStyle(.titleAndIcon)
            .font(.caption)
            .foregroundStyle(.secondary)

            Label {
                Text(equalizerSettings.isFlat ? "Audio: Flat" : "Audio: \(equalizerSettings.formattedSummary())")
            } icon: {
                Image(systemName: "slider.horizontal.3")
            }
            .font(.caption2)
            .foregroundStyle(equalizerSettings.isFlat ? Color.secondary : DesignSystem.Colors.accentBlue)

            if let transcript = recording.transcript, !transcript.isEmpty {
                Text(transcript)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text("Transcript not available yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                .fill(isSelected ? DesignSystem.Colors.accentBlue.opacity(0.15) : Color.clear)
        )
    }
}

#Preview {
    FilesView()
        .environmentObject(AudioRecorder())
        .environmentObject(AudioPlayer())
}
