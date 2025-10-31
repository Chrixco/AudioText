import SwiftUI
import AVFoundation

/// Interactive waveform timeline that shows the full audio recording's shape
/// and allows scrubbing by tapping or dragging along the timeline
struct WaveformTimeline: View {
    let recording: RecordingFile
    let progress: Double // 0.0 to 1.0
    let isPlaying: Bool
    let onSeek: (Double) -> Void

    @State private var waveformData: [Float] = []
    @State private var isLoadingWaveform = false
    @State private var isDragging = false

    private let sampleCount = 100
    private let barSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background - Soft debossed/inset (reference style)
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.control, style: .continuous)
                    .fill(DesignSystem.Colors.background)
                    .shadow(color: DesignSystem.Colors.shadowDark, radius: 10, x: 4, y: 4)
                    .shadow(color: DesignSystem.Colors.shadowLight, radius: 8, x: -3, y: -3)

                // Waveform bars
                HStack(alignment: .center, spacing: barSpacing) {
                    ForEach(0..<waveformData.count, id: \.self) { index in
                        WaveformBar(
                            amplitude: CGFloat(waveformData[index]),
                            maxHeight: geometry.size.height - 16,
                            isPast: barIsPast(index: index, totalBars: waveformData.count, progress: progress),
                            isPlaying: isPlaying
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)

                // Playhead indicator
                if !waveformData.isEmpty {
                    PlayheadIndicator(
                        progress: progress,
                        width: geometry.size.width,
                        isPlaying: isPlaying
                    )
                }

                // Loading or empty state
                if isLoadingWaveform {
                    VStack {
                        ProgressView()
                        Text("Loading waveform...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if waveformData.isEmpty {
                    Text("Waveform")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let position = max(0, min(1, value.location.x / geometry.size.width))
                        onSeek(position)
                        HapticManager.shared.selection()
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 80)
        .task(id: recording.id) {
            await loadWaveform()
        }
    }

    private func loadWaveform() async {
        guard waveformData.isEmpty else { return }
        isLoadingWaveform = true

        let samples = await extractWaveformData(from: recording.fileURL, sampleCount: sampleCount)

        await MainActor.run {
            waveformData = samples
            isLoadingWaveform = false
        }
    }

    private func barIsPast(index: Int, totalBars: Int, progress: Double) -> Bool {
        guard totalBars > 0 else { return false }
        // Calculate the center position of this bar as a fraction of the total
        let barCenterPosition = (Double(index) + 0.5) / Double(totalBars)
        // Bar is "past" if its center is before or at the current progress
        return barCenterPosition <= progress
    }

    private func extractWaveformData(from url: URL, sampleCount: Int) async -> [Float] {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return Array(repeating: 0.3, count: sampleCount)
            }

            try audioFile.read(into: buffer)

            guard let floatData = buffer.floatChannelData?[0] else {
                return Array(repeating: 0.3, count: sampleCount)
            }

            let samples = stride(from: 0, to: Int(frameCount), by: max(1, Int(frameCount) / sampleCount))
                .map { index -> Float in
                    let start = index
                    let end = min(index + max(1, Int(frameCount) / sampleCount), Int(frameCount))
                    var sum: Float = 0
                    var count = 0

                    for i in start..<end {
                        sum += abs(floatData[i])
                        count += 1
                    }

                    let average = count > 0 ? sum / Float(count) : 0
                    return min(1.0, average * 3.0) // Amplify for visibility
                }

            // Ensure we have exactly sampleCount samples
            let normalized = Array(samples.prefix(sampleCount))
            if normalized.count < sampleCount {
                return normalized + Array(repeating: 0.1, count: sampleCount - normalized.count)
            }

            return normalized

        } catch {
            print("❌ Failed to extract waveform: \(error)")
            return Array(repeating: 0.3, count: sampleCount)
        }
    }
}

/// Individual waveform bar
private struct WaveformBar: View {
    let amplitude: CGFloat
    let maxHeight: CGFloat
    let isPast: Bool
    let isPlaying: Bool

    private var barHeight: CGFloat {
        max(2, amplitude * maxHeight)
    }

    private var barColor: Color {
        if isPast {
            return isPlaying ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.accentBlue.opacity(0.6)
        } else {
            return DesignSystem.Colors.textTertiary.opacity(0.3)
        }
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(barColor)
                .frame(width: 4, height: barHeight)
                .animation(.easeOut(duration: 0.15), value: isPast)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: maxHeight)
    }
}

/// Playhead indicator that moves along the timeline
private struct PlayheadIndicator: View {
    let progress: Double
    let width: CGFloat
    let isPlaying: Bool

    private var offset: CGFloat {
        // Map progress (0-1) to horizontal position (0 to width)
        // Clamp to ensure it stays within bounds
        let position = CGFloat(max(0, min(1, progress))) * width
        return position
    }

    var body: some View {
        ZStack {
            // Vertical line
            Rectangle()
                .fill(DesignSystem.Colors.accentBlue)
                .frame(width: 2)

            // Top circle
            Circle()
                .fill(DesignSystem.Colors.accentBlue)
                .frame(width: 8, height: 8)
                .offset(y: -36)

            // Glow effect when playing
            if isPlaying {
                Circle()
                    .fill(DesignSystem.Colors.accentBlue.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .offset(y: -36)
                    .blur(radius: 4)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPlaying)
            }
        }
        .frame(width: 2)
        .offset(x: offset)
        .animation(.linear(duration: 0.1), value: offset)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Waveform Timeline Preview")
            .font(.headline)

        WaveformTimeline(
            recording: RecordingFile(
                fileName: "test.m4a",
                fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
                duration: 120,
                dateCreated: Date(),
                fileSize: 1024,
                transcript: nil
            ),
            progress: 0.3,
            isPlaying: true,
            onSeek: { position in
                print("Seek to: \(position)")
            }
        )
        .padding()
    }
    .frame(width: 400, height: 200)
}
