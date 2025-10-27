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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if audioRecorder.recordings.isEmpty {
                        emptyState
                    } else {
                        recordingsList
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Text("\(audioRecorder.recordings.count) recordings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            if let recording = recordingToShare {
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
                RecordingListRow(
                    recording: recording,
                    isSelected: recording.id == quickSelectedRecordingID,
                    equalizerSettings: audioRecorder.equalizerSettings(for: recording),
                    onPlayTapped: {
                        quickSelectedRecordingID = recording.id
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
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 300)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
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
}
