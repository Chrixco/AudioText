import SwiftUI

/// Neumorphic playback controls including skip buttons and speed selector
struct NeumorphicPlaybackControls: View {
    var onSkipBackward: () -> Void
    var onSkipForward: () -> Void
    var playbackRate: Float
    var onRateChange: (Float) -> Void

    private let skipInterval: TimeInterval = 15  // 15 seconds

    var body: some View {
        VStack(spacing: 20) {
            // Skip Controls
            HStack(spacing: 32) {
                SkipButton(
                    direction: .backward,
                    interval: skipInterval,
                    action: onSkipBackward
                )

                SkipButton(
                    direction: .forward,
                    interval: skipInterval,
                    action: onSkipForward
                )
            }

            // Playback Speed Control
            PlaybackSpeedSelector(
                selectedRate: playbackRate,
                onRateChange: onRateChange
            )
        }
    }
}

// MARK: - Skip Button

private struct SkipButton: View {
    enum Direction {
        case forward
        case backward

        var iconName: String {
            switch self {
            case .forward: return "goforward.15"
            case .backward: return "gobackward.15"
            }
        }

        var label: String {
            switch self {
            case .forward: return "Skip Forward"
            case .backward: return "Skip Backward"
            }
        }
    }

    let direction: Direction
    let interval: TimeInterval
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            ZStack {
                // Neumorphic circle background
                Circle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 72, height: 72)
                    .applyShadows(
                        isPressed
                            ? DesignSystem.NeumorphicShadow.mediumDebossed()
                            : DesignSystem.NeumorphicShadow.mediumEmbossed()
                    )

                // Icon
                Image(systemName: direction.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(direction.label)
        .accessibilityHint("Skip \(Int(interval)) seconds")
    }
}

// MARK: - Playback Speed Selector

private struct PlaybackSpeedSelector: View {
    let selectedRate: Float
    let onRateChange: (Float) -> Void

    private let availableRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        VStack(spacing: 10) {
            Text("Playback Speed")
                .font(DesignSystem.Typography.captionLarge)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Neumorphic segmented control
            HStack(spacing: 8) {
                ForEach(availableRates, id: \.self) { rate in
                    SpeedButton(
                        rate: rate,
                        isSelected: abs(selectedRate - rate) < 0.01,
                        onTap: {
                            HapticManager.shared.selection()
                            onRateChange(rate)
                        }
                    )
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(DesignSystem.Colors.background)
                    .applyShadows(DesignSystem.NeumorphicShadow.mediumDebossed())
            )
        }
    }
}

private struct SpeedButton: View {
    let rate: Float
    let isSelected: Bool
    let onTap: () -> Void

    private var displayText: String {
        if rate == 1.0 {
            return "1×"
        } else {
            return String(format: "%.2g×", rate)
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    isSelected
                        ? DesignSystem.Colors.accentBlue
                        : DesignSystem.Colors.textSecondary
                )
                .frame(width: 48, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous)
                        .fill(
                            isSelected
                                ? DesignSystem.Colors.surface
                                : Color.clear
                        )
                        .applyShadows(
                            isSelected
                                ? DesignSystem.NeumorphicShadow.smallEmbossed()
                                : []
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Pressable Button Style

private struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Playback Controls") {
    VStack(spacing: 40) {
        NeumorphicPlaybackControls(
            onSkipBackward: { print("Skip backward") },
            onSkipForward: { print("Skip forward") },
            playbackRate: 1.0,
            onRateChange: { rate in print("Rate changed to \(rate)") }
        )

        NeumorphicPlaybackControls(
            onSkipBackward: { print("Skip backward") },
            onSkipForward: { print("Skip forward") },
            playbackRate: 1.5,
            onRateChange: { rate in print("Rate changed to \(rate)") }
        )
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
}
