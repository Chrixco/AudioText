import SwiftUI
import Combine

/// Neumorphic audio visualizer with VU meter bars and debossed container
struct NeumorphicAudioVisualizer: View {
    let isActive: Bool
    let levelProvider: () -> Float

    @State private var audioLevels: [Double] = Array(repeating: 0.0, count: 32)
    @State private var timerCancellable: AnyCancellable?

    let barCount = 32
    let barWidth: CGFloat = 6.0
    let maxBarHeight: CGFloat = 50.0

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

            // Visualizer bars in black container
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    NeumorphicAudioBar(
                        height: audioLevels[index] * maxBarHeight,
                        width: barWidth,
                        maxHeight: maxBarHeight
                    )
                }
            }
            .frame(height: maxBarHeight + 8)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.xSmall)
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
        for i in 0..<barCount {
            let variation = sin(Double(i) * 0.1) * 0.3 + 0.7
            let adjusted = clamped * variation
            audioLevels[i] = audioLevels[i] * 0.7 + adjusted * 0.3
        }
    }
}

// MARK: - Neumorphic Audio Bar

private struct NeumorphicAudioBar: View {
    let height: CGFloat
    let width: CGFloat
    let maxHeight: CGFloat

    // White bars
    private var barColor: Color {
        return Color.white
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            // Embossed bar with gradient
            RoundedRectangle(cornerRadius: width / 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [barColor, barColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: max(height, 2))
                .overlay(
                    RoundedRectangle(cornerRadius: width / 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: barColor.opacity(0.4), radius: 2, x: 0, y: 1)
                .opacity(height > 2 ? 1.0 : 0.3)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: maxHeight)
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
