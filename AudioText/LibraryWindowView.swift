import SwiftUI

struct LibraryWindowView: View {
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var audioPlayer: AudioPlayer

    @State private var quickSelectedRecordingID: UUID?
    @State private var showingRenameAlert = false
    @State private var recordingToRename: RecordingFile?
    @State private var renameText = ""
    @State private var renameError: String?
    @State private var showingShareSheet = false
    @State private var recordingToShare: RecordingFile?
    @State private var panelScriptRecording: RecordingFile?

    // Edit mode state
    @State private var isEditMode = false
    @State private var selectedRecordings: Set<UUID> = []
    @State private var itemsToShare: [URL] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if audioRecorder.recordings.isEmpty {
                        emptyState
                    } else {
                        recordingsList
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if !isEditMode {
                        Text("\(audioRecorder.recordings.count) recordings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(selectedRecordings.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !audioRecorder.recordings.isEmpty {
                        Button(isEditMode ? "Done" : "Edit") {
                            withAnimation {
                                isEditMode.toggle()
                                if !isEditMode {
                                    selectedRecordings.removeAll()
                                }
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isEditMode && !selectedRecordings.isEmpty {
                    bottomToolbar
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
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
#if os(iOS)
        .sheet(isPresented: $showingShareSheet) {
            if !itemsToShare.isEmpty {
                ShareSheet(items: itemsToShare)
                    .onDisappear {
                        itemsToShare.removeAll()
                    }
            } else if let recording = recordingToShare {
                ShareSheet(items: [recording.fileURL])
            }
        }
        .sheet(item: $panelScriptRecording) { recording in
            TranscriptionView(
                transcription: recording.transcript ?? "No transcript is available for this recording yet."
            )
        }
#endif
    }

    private var recordingsList: some View {
        VStack(spacing: 16) {
            ForEach(audioRecorder.recordings) { recording in
                HStack(spacing: 12) {
                    // Selection checkmark
                    if isEditMode {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedRecordings.contains(recording.id) {
                                    selectedRecordings.remove(recording.id)
                                } else {
                                    selectedRecordings.insert(recording.id)
                                }
                                HapticManager.shared.selection()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .strokeBorder(
                                        selectedRecordings.contains(recording.id) ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textTertiary.opacity(0.5),
                                        lineWidth: 2
                                    )
                                    .background(
                                        Circle()
                                            .fill(selectedRecordings.contains(recording.id) ? DesignSystem.Colors.accentBlue : Color.clear)
                                    )
                                    .frame(width: 24, height: 24)

                                if selectedRecordings.contains(recording.id) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }

                    RecordingListRow(
                        recording: recording,
                        isSelected: recording.id == quickSelectedRecordingID,
                        equalizerSettings: audioRecorder.equalizerSettings(for: recording),
                        onPlayTapped: isEditMode ? nil : {
                            quickSelectedRecordingID = recording.id
                            togglePlayback(for: recording)
                        }
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditMode {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedRecordings.contains(recording.id) {
                                selectedRecordings.remove(recording.id)
                            } else {
                                selectedRecordings.insert(recording.id)
                            }
                            HapticManager.shared.selection()
                        }
                    } else {
                        quickSelectedRecordingID = recording.id
                    }
                }
                .contextMenu {
                    if !isEditMode {
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No recordings yet")
                .font(.title3.weight(.semibold))
            Text("Capture audio to see your files here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.surface)
                .shadow(color: DesignSystem.Colors.shadowDark.opacity(0.2), radius: 4, x: 2, y: 2)
                .shadow(color: DesignSystem.Colors.highlightLight, radius: 4, x: -2, y: -2)
        )
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

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            // Delete button
            Button {
                batchDeleteRecordings()
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(selectedRecordings.isEmpty)

            // Share button
            Button {
                batchShareRecordings()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(selectedRecordings.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Batch Actions
    private func batchDeleteRecordings() {
        let recordingsToDelete = audioRecorder.recordings.filter { selectedRecordings.contains($0.id) }

        for recording in recordingsToDelete {
            do {
                try FileManager.default.removeItem(at: recording.fileURL)
            } catch {
                print("Failed to delete recording: \(error.localizedDescription)")
            }
        }

        audioRecorder.recordings.removeAll { selectedRecordings.contains($0.id) }
        selectedRecordings.removeAll()
        HapticManager.shared.destructiveAction()

        // Exit edit mode if no recordings left
        if audioRecorder.recordings.isEmpty {
            withAnimation {
                isEditMode = false
            }
        }
    }

    private func batchShareRecordings() {
        let recordingsToShare = audioRecorder.recordings.filter { selectedRecordings.contains($0.id) }
        itemsToShare = recordingsToShare.map { $0.fileURL }
        showingShareSheet = true
    }
}
