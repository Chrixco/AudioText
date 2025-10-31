import SwiftUI

#if os(iOS)
import AVFoundation

/// Neumorphic audio input mode selector with segmented embossed/debossed buttons
struct NeumorphicInputModeSelector: View {
    let selectedMode: AudioInputMode
    let isExternalAvailable: Bool
    let isBluetoothAvailable: Bool
    let onSelect: (AudioInputMode) -> Void

    private var availableModes: [AudioInputMode] {
        AudioInputMode.allCases.filter { mode in
            switch mode {
            case .builtIn, .automatic:
                return true
            case .external:
                return isExternalAvailable || isBluetoothAvailable
            }
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxSmall) {
            ForEach(availableModes, id: \.self) { mode in
                InputModeButton(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    action: {
                        withAnimation(DesignSystem.Animation.spring) {
                            onSelect(mode)
                            HapticManager.shared.selection()
                        }
                    }
                )
            }
        }
        .padding(DesignSystem.Spacing.xxSmall)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(DesignSystem.Colors.background)
        )
        .applyShadows(DesignSystem.NeumorphicShadow.mediumDebossed())
    }
}

// MARK: - Input Mode Button

private struct InputModeButton: View {
    let mode: AudioInputMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxSmall) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textSecondary)

                Text(mode.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous)
                    .fill(isSelected ? DesignSystem.Colors.surface : DesignSystem.Colors.surfaceDepressed)
            )
            .applyShadows(isSelected ? DesignSystem.NeumorphicShadow.mediumEmbossed() : DesignSystem.NeumorphicShadow.mediumDebossed())
            .scaleEffect(isSelected ? 1.0 : 0.97)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Input Mode Selector") {
    VStack(spacing: 32) {
        Text("Audio Input Mode Selector")
            .font(DesignSystem.Typography.headlineSmall)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

        // All modes available
        NeumorphicInputModeSelector(
            selectedMode: .builtIn,
            isExternalAvailable: true,
            isBluetoothAvailable: true,
            onSelect: { mode in print("Selected: \(mode.title)") }
        )

        NeumorphicInputModeSelector(
            selectedMode: .external,
            isExternalAvailable: true,
            isBluetoothAvailable: true,
            onSelect: { mode in print("Selected: \(mode.title)") }
        )

        NeumorphicInputModeSelector(
            selectedMode: .automatic,
            isExternalAvailable: true,
            isBluetoothAvailable: true,
            onSelect: { mode in print("Selected: \(mode.title)") }
        )

        // Only built-in available
        Text("Limited Modes (No External)")
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundStyle(DesignSystem.Colors.textSecondary)

        NeumorphicInputModeSelector(
            selectedMode: .builtIn,
            isExternalAvailable: false,
            isBluetoothAvailable: false,
            onSelect: { mode in print("Selected: \(mode.title)") }
        )

        Spacer()
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.light)
}
#endif
