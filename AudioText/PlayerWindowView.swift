import SwiftUI

struct PlayerWindowView: View {
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var audioPlayer: AudioPlayer

    @State private var selectedRecordingID: UUID?
    @State private var panelScriptRecording: RecordingFile?

    var selectedRecording: RecordingFile? {
        if let id = selectedRecordingID {
            return audioRecorder.recordings.first { $0.id == id }
        }
        return audioRecorder.recordings.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let recording = selectedRecording {
                        recordingSelector

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
                        emptyState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Player")
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            refreshSelection()
        }
        .onChange(of: audioRecorder.recordings) { _, _ in
            refreshSelection()
        }
#if os(iOS)
        .sheet(item: $panelScriptRecording) { recording in
            TranscriptionView(
                transcription: recording.transcript ?? "No transcript is available for this recording yet."
            )
        }
#endif
    }

    private var recordingSelector: some View {
        Menu {
            ForEach(audioRecorder.recordings) { recording in
                Button {
                    selectedRecordingID = recording.id
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
            HStack {
                Text(selectedRecording?.fileName ?? "Select Recording")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.blue.opacity(0.08))
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No recordings yet")
                .font(.title3.weight(.semibold))
            Text("Capture a clip to start tuning your custom equalizer profile.")
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

    private func refreshSelection() {
        if let id = selectedRecordingID,
           audioRecorder.recordings.contains(where: { $0.id == id }) {
            return
        }
        selectedRecordingID = audioRecorder.recordings.first?.id
    }
}
