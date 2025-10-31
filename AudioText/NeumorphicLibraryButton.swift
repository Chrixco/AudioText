import SwiftUI

/// Neumorphic library button with badge for recording count
struct NeumorphicLibraryButton: View {
    let recordingCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.small) {
                // Icon with badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: DesignSystem.ComponentSize.iconLarge, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accentBlue)
                        .frame(width: 32, height: 32)

                    // Badge
                    if recordingCount > 0 {
                        Text("\(recordingCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.Colors.recording)
                            )
                            .shadow(color: DesignSystem.Colors.recording.opacity(0.4), radius: 3, x: 0, y: 1)
                            .offset(x: 8, y: -8)
                    }
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text("Library")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(recordingCountText)
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.vertical, DesignSystem.Spacing.small)
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(DesignSystem.Colors.surface)
            )
            .applyShadows(DesignSystem.NeumorphicShadow.mediumEmbossed())
        }
        .buttonStyle(LibraryButtonStyle())
    }

    private var recordingCountText: String {
        if recordingCount == 0 {
            return "No recordings"
        } else if recordingCount == 1 {
            return "1 recording"
        } else {
            return "\(recordingCount) recordings"
        }
    }
}

// MARK: - Library Button Style

private struct LibraryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Library Button") {
    VStack(spacing: 32) {
        Text("Library Button")
            .font(DesignSystem.Typography.headlineSmall)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

        // No recordings
        NeumorphicLibraryButton(
            recordingCount: 0,
            action: { print("Open library") }
        )

        // One recording
        NeumorphicLibraryButton(
            recordingCount: 1,
            action: { print("Open library") }
        )

        // Multiple recordings
        NeumorphicLibraryButton(
            recordingCount: 42,
            action: { print("Open library") }
        )

        // Large number
        NeumorphicLibraryButton(
            recordingCount: 999,
            action: { print("Open library") }
        )

        Spacer()
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.light)
}
