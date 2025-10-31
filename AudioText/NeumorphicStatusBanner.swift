import SwiftUI

/// Neumorphic status banner with debossed appearance and state-dependent styling
struct NeumorphicStatusBanner: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let isRecording: Bool

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.small) {
            // Icon with subtle embossed circle background
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 40, height: 40)
                    .applyShadows(DesignSystem.NeumorphicShadow.smallEmbossed())

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            // Text content with proper truncation
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxSmall) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 0)

            // Subtle pulsing indicator when recording
            if isRecording {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .blur(radius: 2)
                    )
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isRecording
                    )
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(DesignSystem.Colors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .strokeBorder(color.opacity(0.2), lineWidth: 1.5)
        )
        .applyShadows(DesignSystem.NeumorphicShadow.mediumDebossed())
    }
}

// MARK: - Preview

#Preview("Status Banner States") {
    VStack(spacing: 24) {
        // Idle state
        NeumorphicStatusBanner(
            icon: "checkmark.circle.fill",
            title: "Ready to Record",
            subtitle: "Tap the microphone button to start",
            color: DesignSystem.Colors.accentBlue,
            isRecording: false
        )

        // Recording state
        NeumorphicStatusBanner(
            icon: "waveform.circle.fill",
            title: "Recording in progress",
            subtitle: "System Language - High Quality Mode",
            color: DesignSystem.Colors.recording,
            isRecording: true
        )

        // Playing state
        NeumorphicStatusBanner(
            icon: "play.circle.fill",
            title: "Playing: Meeting Notes",
            subtitle: "2:34 / 15:42",
            color: DesignSystem.Colors.accentBlue,
            isRecording: false
        )

        // Long text truncation test
        NeumorphicStatusBanner(
            icon: "exclamationmark.triangle.fill",
            title: "This is a very long title that should truncate properly",
            subtitle: "And this is an even longer subtitle that also needs to truncate to avoid overflow issues on small screens",
            color: DesignSystem.Colors.warning,
            isRecording: false
        )
    }
    .padding(20)
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.light)
}

// MARK: - View Extension for Multi-Layer Shadows

