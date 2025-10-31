import SwiftUI
import Combine

/// Neumorphic audio visualizer with horizontal white bars on black background
/// Bars get progressively smaller as they go up (like stacked levels)
struct NeumorphicAudioVisualizer: View {
    let isActive: Bool
    let levelProvider: () -> Float

    @State private var audioLevels: [Double] = Array(repeating: 0.0, count: 16)
    @State private var timerCancellable: AnyCancellable?

    let barCount = 16
    let barHeight: CGFloat = 4.0
    let barSpacing: CGFloat = 3.0
    let maxBarWidth: CGFloat = 280.0

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

            // Visualizer bars in black container (horizontal bars)
            VStack(spacing: barSpacing) {
                // Bars from top to bottom (index 0 is smallest at top)
                ForEach((0..<barCount).reversed(), id: \.self) { index in
                    HorizontalAudioBar(
                        width: audioLevels[index] * maxBarWidth,
                        height: barHeight,
                        barIndex: index,
                        maxIndex: barCount
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.small)
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
            audioLevels = Array(repeating: 0.0, count: barCount)
        }
    }

    private func updateLevels(with newValue: Double) {
        let clamped = max(0, min(1, newValue))

        // Update levels with smooth interpolation
        // Higher index = higher bar = should activate at higher levels
        for i in 0..<barCount {
            let threshold = Double(i) / Double(barCount)
            let activation = max(0, clamped - threshold) * Double(barCount)
            let targetLevel = min(1.0, activation)

            // Smooth interpolation with some variation
            let variation = sin(Double(i) * 0.2) * 0.1 + 1.0
            audioLevels[i] = audioLevels[i] * 0.6 + targetLevel * variation * 0.4
        }
    }
}

// MARK: - Horizontal Audio Bar

private struct HorizontalAudioBar: View {
    let width: CGFloat
    let height: CGFloat
    let barIndex: Int
    let maxIndex: Int

    // Calculate max width based on position (smaller bars at top)
    private var maxBarWidth: CGFloat {
        let ratio = CGFloat(barIndex + 1) / CGFloat(maxIndex)
        // Top bars are 40% of bottom bars
        return 280.0 * (0.4 + (ratio * 0.6))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Center-aligned horizontal bar
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: min(width, maxBarWidth), height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: Color.white.opacity(0.3), radius: 1, x: 0, y: 0)
                .opacity(width > 2 ? 1.0 : 0.2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: maxBarWidth)
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
