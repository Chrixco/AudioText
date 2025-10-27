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
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done", action: dismiss.callAsFunction)
            }
        }
#else
        .background(Color(NSColor.windowBackgroundColor))
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
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            Text("No Recordings Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Start a new recording from the main screen. Your clips, audio levels, and scripts will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
            return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
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
    @State private var workingEqualizer: EqualizerSettings
    @State private var activePage = 0
    @State private var shareItems: [Any] = []
    @State private var isSharing = false
    @State private var isExporting = false
    @State private var exportErrorMessage: String?

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
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

            TabView(selection: $activePage) {
                playbackPage
                    .tag(0)
                    .accessibilityLabel("Playback controls")

                equalizerPage
                    .tag(1)
                    .accessibilityLabel("Player settings")
            }
#if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
#endif
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 520)
        .padding(.vertical, 4)
        .onChange(of: equalizerSettings) { newValue in
            if newValue != workingEqualizer {
                workingEqualizer = newValue
            }
        }
        .onChange(of: recording.id) { _ in
            workingEqualizer = equalizerSettings
            activePage = 0
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
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.blue.opacity(0.12))
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
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.gray.opacity(0.1))
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
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.blue.opacity(0.12))
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

    private var equalizerPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Audio Settings", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(equalizerSettings.formattedSummary())
                    .font(.caption)
                    .foregroundStyle(equalizerSettings.isFlat ? Color.secondary : Color.blue)
            }

            Text("Swipe → to fine-tune this mix. Save profiles per recording for consistent playback.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
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

    private var playbackPage: some View {
        VStack(spacing: 24) {
            AudioVisualizer(
                isActive: isCurrentlyPlaying,
                levelProvider: { audioPlayer.currentLevel() }
            )
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
            )

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
            .frame(width: 220, height: 220)
            .onAppear(perform: syncKnobWithPlayer)
            .onChange(of: audioPlayer.currentTime) { _ in
                guard !isEditing, isTrackingCurrentRecording, audioPlayer.duration > 0 else { return }
                knobValue = audioPlayer.progress
            }
            .onChange(of: audioPlayer.currentRecording?.id) { _ in
                syncKnobWithPlayer()
            }

            VStack(spacing: 8) {
                Text(cleanRecordingName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                Text(timeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            scriptControl
            exportControls
            equalizerPreview
        }
        .padding(24)
    }

    private var equalizerPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Player")
                        .font(.title3.weight(.semibold))
                    Text("Dial in classic five-band EQ curves plus output trim, then save them to this recording.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 18) {
                        ForEach(tonalBands) { band in
                            EqualizerBandControl(
                                band: band,
                                value: binding(for: band)
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Output Gain")
                        .font(.subheadline.weight(.semibold))
                    EqualizerBandControl(
                        band: .preGain,
                        value: binding(for: .preGain)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                presetsSection

                VStack(spacing: 12) {
                    if isEqualizerDirty {
                        Text("Unsaved changes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Saved profile: \(equalizerSettings.formattedSummary())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
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
            .padding(24)
        }
    }

    private var tonalBands: [EqualizerBand] {
        EqualizerBand.allCases.filter { $0 != .preGain }
    }

    private var isEqualizerDirty: Bool {
        workingEqualizer != equalizerSettings
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(EqualizerPreset.allCases) { preset in
                        Button {
                            workingEqualizer = preset.settings
                        } label: {
                            Text(preset.title)
                                .font(.caption.weight(.medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule()
                                        .fill(preset.settings == workingEqualizer ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
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
        activePage = 0
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

    private let barWidth: CGFloat = 52
    private let barHeight: CGFloat = 180

    var body: some View {
        VStack(spacing: 8) {
            Text(formattedValue)
                .font(.caption2.monospacedDigit())
                .frame(maxWidth: .infinity)

            GeometryReader { proxy in
                let height = proxy.size.height

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.gray.opacity(0.16))

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.15), Color.blue],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: max(4, height * normalizedValue))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let clampedY = min(max(0, gesture.location.y), height)
                            let ratio = 1 - (clampedY / height)
                            let range = band.gainRange
                            let mapped = range.lowerBound + Double(ratio) * (range.upperBound - range.lowerBound)
                            let step = max(band.step, 0.1)
                            let quantized = (mapped / step).rounded() * step
                            let clampedValue = min(max(quantized, range.lowerBound), range.upperBound)
                            value = clampedValue
                        }
                )
            }
            .frame(width: barWidth, height: barHeight)

            VStack(spacing: 2) {
                Text(band.title)
                    .font(.caption2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(band.frequencyLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: barWidth + 8)
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
            case .decrement:
                value = max(value - step, range.lowerBound)
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
            .foregroundStyle(equalizerSettings.isFlat ? Color.secondary : Color.blue)

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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
        )
    }
}

#Preview {
    FilesView()
        .environmentObject(AudioRecorder())
        .environmentObject(AudioPlayer())
}
