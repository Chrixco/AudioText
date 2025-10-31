import SwiftUI

/// Hero neumorphic recording button with extreme tactile depth and state transitions
struct NeumorphicRecordingButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var isPressed = false

    private let buttonSize: CGFloat = 140
    private let iconSize: CGFloat = 44

    var body: some View {
        Button(action: {
            HapticManager.shared.medium()
            action()
        }) {
            ZStack {
                // Outer glow when recording
                if isRecording {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignSystem.Colors.recording.opacity(0.4),
                                    DesignSystem.Colors.recording.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: buttonSize / 2,
                                endRadius: buttonSize
                            )
                        )
                        .frame(width: buttonSize + 40, height: buttonSize + 40)
                        .blur(radius: 10)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isRecording
                        )
                }

                // Main button circle
                Circle()
                    .fill(isPressed ? DesignSystem.Colors.surfaceDepressed : DesignSystem.Colors.surface)
                    .frame(width: buttonSize, height: buttonSize)
                    .applyShadows(
                        isPressed
                            ? DesignSystem.NeumorphicShadow.deepDebossed()
                            : DesignSystem.NeumorphicShadow.largeEmbossed()
                    )

                // Inner decorative ring
                Circle()
                    .stroke(
                        isRecording
                            ? DesignSystem.Colors.recording.opacity(0.3)
                            : DesignSystem.Colors.textTertiary.opacity(0.2),
                        lineWidth: 2
                    )
                    .frame(width: buttonSize - 20, height: buttonSize - 20)

                // Icon and label
                VStack(spacing: DesignSystem.Spacing.xSmall) {
                    // Icon with subtle inner shadow effect
                    ZStack {
                        if isRecording {
                            // Stop icon
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(DesignSystem.Colors.recording)
                                .frame(width: iconSize * 0.7, height: iconSize * 0.7)
                                .shadow(color: DesignSystem.Colors.recording.opacity(0.4), radius: 8, x: 0, y: 2)
                        } else {
                            // Microphone icon
                            Image(systemName: "mic.fill")
                                .font(.system(size: iconSize, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            DesignSystem.Colors.accentBlue,
                                            DesignSystem.Colors.accentCyan
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: DesignSystem.Colors.accentBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .frame(height: iconSize)

                    // Label
                    Text(isRecording ? "STOP" : "RECORD")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(
                            isRecording
                                ? DesignSystem.Colors.recording
                                : DesignSystem.Colors.textPrimary
                        )
                }
            }
        }
        .buttonStyle(RecordingButtonStyle(isPressed: $isPressed))
        .frame(width: buttonSize, height: buttonSize)
    }
}

// MARK: - Recording Button Style

private struct RecordingButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Recording Button") {
    VStack(spacing: 48) {
        Text("Recording Button")
            .font(DesignSystem.Typography.headlineSmall)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

        // Idle state
        VStack(spacing: 16) {
            Text("Idle State")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            NeumorphicRecordingButton(
                isRecording: false,
                action: { print("Start recording") }
            )
        }

        // Recording state
        VStack(spacing: 16) {
            Text("Recording State")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            NeumorphicRecordingButton(
                isRecording: true,
                action: { print("Stop recording") }
            )
        }

        Spacer()
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.light)
}
