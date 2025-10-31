import SwiftUI
import Combine

/// Neumorphic audio visualizer - 2 rows × 3 vertical bars on black background
/// Bars get progressively thinner as they go higher
struct NeumorphicAudioVisualizer: View {
    let isActive: Bool
    let levelProvider: () -> Float

    @State private var audioLevels: [Double] = Array(repeating: 0.0, count: 6)
    @State private var timerCancellable: AnyCancellable?

    let totalBars = 6  // 2 rows × 3 bars
    let barsPerRow = 3

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Title
            HStack {
                Text("LEVEL")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .tracking(1.5)

                Spacer()

                // Peak indicator
                Circle()
                    .fill(peakColor)
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, DesignSystem.Spacing.small)

            // Visualizer bars in black container (2 rows of 3 vertical bars)
            VStack(spacing: 8) {
                // Bottom row (indices 0, 1, 2) - thickest bars
                HStack(spacing: 8) {
                    ForEach(0..<barsPerRow, id: \.self) { index in
                        VerticalAudioBar(
                            level: audioLevels[index],
                            barIndex: index,
                            rowIndex: 0
                        )
                    }
                }

                // Top row (indices 3, 4, 5) - thinner bars
                HStack(spacing: 8) {
                    ForEach(barsPerRow..<totalBars, id: \.self) { index in
                        VerticalAudioBar(
                            level: audioLevels[index],
                            barIndex: index - barsPerRow,
                            rowIndex: 1
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous)
                    .fill(Color.black)
            )
            .applyShadows(DesignSystem.NeumorphicShadow.deepDebossed())
        }
        .padding(DesignSystem.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(DesignSystem.Colors.surface)
        )
        .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
        .onAppear {
            if isActive {
                start()
            }
        }
        .onDisappear(perform: stop)
        .onChange(of: isActive) { _, active in
            active ? start() : stop()
        }
    }

    private var peakColor: Color {
        let maxLevel = audioLevels.max() ?? 0
        if maxLevel > 0.95 {
            return DesignSystem.Colors.error
        } else if maxLevel > 0.85 {
            return DesignSystem.Colors.accentOrange
        } else if maxLevel > 0.6 {
            return DesignSystem.Colors.accentYellow
        } else {
            return DesignSystem.Colors.accentGreen
        }
    }

    private func start() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateLevels(with: Double(levelProvider()))
            }
    }

    private func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil

        // Smoothly fall back to silence
        withAnimation(.easeOut(duration: 0.2)) {
            audioLevels = Array(repeating: 0.0, count: totalBars)
        }
    }

    private func updateLevels(with newValue: Double) {
        let clamped = max(0, min(1, newValue))

        // Update levels with smooth interpolation
        // Each bar responds to audio with some variation
        for i in 0..<totalBars {
            let variation = sin(Double(i) * 0.3) * 0.2 + 0.8
            let targetLevel = clamped * variation

            // Smooth interpolation with different speeds for each bar
            let smoothing = 0.65 + (Double(i) * 0.02)
            audioLevels[i] = audioLevels[i] * smoothing + targetLevel * (1 - smoothing)
        }
    }
}

// MARK: - Vertical Audio Bar

private struct VerticalAudioBar: View {
    let level: Double
    let barIndex: Int
    let rowIndex: Int

    // Bar dimensions: thinner bars in top row
    private var barWidth: CGFloat {
        rowIndex == 0 ? 28 : 20  // Bottom row: 28pt, Top row: 20pt
    }

    private let maxBarHeight: CGFloat = 60

    private var barHeight: CGFloat {
        max(2, level * maxBarHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // White vertical bar
            RoundedRectangle(cornerRadius: barWidth / 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: barWidth, height: barHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: barWidth / 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: Color.white.opacity(0.5), radius: 2, x: 0, y: 0)
                .opacity(barHeight > 2 ? 1.0 : 0.3)
        }
        .frame(maxWidth: barWidth, maxHeight: maxBarHeight)
    }
}

// MARK: - Preview

#Preview("Audio Visualizer") {
    VStack(spacing: 32) {
        Text("Audio Visualizer")
            .font(DesignSystem.Typography.headlineSmall)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

        // Active state with animation
        NeumorphicAudioVisualizer(
            isActive: true,
            levelProvider: { Float.random(in: 0.3...0.9) }
        )

        // Low level
        NeumorphicAudioVisualizer(
            isActive: true,
            levelProvider: { 0.3 }
        )

        // High level (near clipping)
        NeumorphicAudioVisualizer(
            isActive: true,
            levelProvider: { 0.95 }
        )

        // Inactive state
        NeumorphicAudioVisualizer(
            isActive: false,
            levelProvider: { 0 }
        )

        Spacer()
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.light)
}
