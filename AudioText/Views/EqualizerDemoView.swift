//
//  EqualizerDemoView.swift
//  AudioText
//
//  Demo view to showcase the new neumorphic equalizer
//

import SwiftUI

struct EqualizerDemoView: View {

    @State private var settings = NeumorphicEqualizerSettings()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Title
                    VStack(spacing: DesignSystem.Spacing.xSmall) {
                        Text("Neumorphic Equalizer")
                            .font(DesignSystem.Typography.headlineLarge)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Built from scratch with SwiftUI")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.large)

                    // Equalizer Panel
                    NeumorphicEqualizerPanel(settings: $settings)

                    // Status Card
                    statusCard

                    // Reset Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            settings.reset()
                        }
                        HapticManager.shared.impact(style: .medium)
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Flat")
                                .font(DesignSystem.Typography.bodyMedium.weight(.semibold))
                        }
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                                .fill(DesignSystem.Colors.surface)
                        )
                        .applyShadows(DesignSystem.NeumorphicShadow.medium())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Current Settings")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Divider()

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                ForEach(NeumorphicEqualizerSettings.Band.allCases) { band in
                    HStack {
                        Text(band.rawValue)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .frame(width: 90, alignment: .leading)

                        Text(band.frequency)
                            .font(DesignSystem.Typography.bodyMedium.monospacedDigit())
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .frame(width: 60, alignment: .leading)

                        Spacer()

                        Text(settings.getPercentageString(for: band))
                            .font(DesignSystem.Typography.bodyMedium.weight(.semibold).monospacedDigit())
                            .foregroundStyle(settings.getColor(for: band))
                    }
                }
            }

            Divider()

            HStack {
                Image(systemName: settings.isFlat ? "checkmark.circle.fill" : "waveform")
                    .foregroundStyle(settings.isFlat ? DesignSystem.Colors.accentGreen : DesignSystem.Colors.accentBlue)

                Text(settings.isFlat ? "Flat profile" : "Custom profile")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.surface)
        )
        .applyShadows(DesignSystem.NeumorphicShadow.medium())
        .padding(.horizontal)
    }
}

#Preview {
    EqualizerDemoView()
}
