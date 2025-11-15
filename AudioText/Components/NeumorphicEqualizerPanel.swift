//
//  NeumorphicEqualizerPanel.swift
//  AudioText
//
//  Two-panel swipeable equalizer with neumorphic design
//

import SwiftUI

struct NeumorphicEqualizerPanel: View {

    // MARK: - Binding

    @Binding var settings: NeumorphicEqualizerSettings

    // MARK: - State

    @State private var currentPanel: Int = 0
    @State private var showPresetPicker: Bool = false
    @State private var enableHaptics: Bool = true

    // MARK: - Constants

    private let panelCount = 2

    // Panel 1 bands: Bass, Low-Mid, Mid
    private let panel1Bands: [NeumorphicEqualizerSettings.Band] = [.bass, .lowMid, .mid]

    // Panel 2 bands: High-Mid, High, Presence
    private let panel2Bands: [NeumorphicEqualizerSettings.Band] = [.highMid, .high, .presence]

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.elementSpacing) {
            // Header
            headerView

            // Two-panel swipeable container
            TabView(selection: $currentPanel) {
                // Panel 1: Bass, Low-Mid, Mid
                panelView(bands: panel1Bands)
                    .tag(0)

                // Panel 2: High-Mid, High, Presence
                panelView(bands: panel2Bands)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)
            .onChange(of: currentPanel) { _ in
                if enableHaptics {
                    HapticManager.shared.impact(style: .medium)
                }
            }

            // Page indicators
            pageIndicators

            // Preset selector button
            presetButton
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.surface)
        )
        .applyShadows(DesignSystem.NeumorphicShadow.large())
        .sheet(isPresented: $showPresetPicker) {
            presetPickerSheet
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equalizer")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Swipe to explore • Visual feedback")
                        .font(DesignSystem.Typography.captionLarge)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Haptics toggle
                Button(action: {
                    enableHaptics.toggle()
                    if enableHaptics {
                        HapticManager.shared.selection()
                    }
                }) {
                    Image(systemName: enableHaptics ? "hand.tap.fill" : "hand.tap")
                        .font(.system(size: 20))
                        .foregroundStyle(enableHaptics ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textTertiary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Panel View

    private func panelView(bands: [NeumorphicEqualizerSettings.Band]) -> some View {
        HStack(spacing: DesignSystem.Spacing.elementSpacing) {
            ForEach(bands) { band in
                NeumorphicEqualizerSlider(
                    band: band,
                    value: Binding(
                        get: { settings.getValue(for: band) },
                        set: { settings.setValue($0, for: band) }
                    ),
                    enableHaptics: enableHaptics
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: DesignSystem.Spacing.xSmall) {
            ForEach(0..<panelCount, id: \.self) { index in
                Circle()
                    .fill(currentPanel == index ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textTertiary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPanel == index ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPanel)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            currentPanel = index
                        }
                    }
            }
        }
    }

    // MARK: - Preset Button

    private var presetButton: some View {
        Button(action: {
            showPresetPicker = true
            if enableHaptics {
                HapticManager.shared.selection()
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "slider.horizontal.3")
                    .font(DesignSystem.Typography.bodyMedium.weight(.medium))

                Text("Select Preset")
                    .font(DesignSystem.Typography.bodyMedium.weight(.medium))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.bodySmall.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(DesignSystem.Colors.surface)
            )
            .applyShadows(DesignSystem.NeumorphicShadow.medium())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preset Picker Sheet

    private var presetPickerSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(NeumorphicEqualizerSettings.Preset.allPresets) { preset in
                        presetRow(preset)
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Equalizer Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showPresetPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Preset Row

    private func presetRow(_ preset: NeumorphicEqualizerSettings.Preset) -> some View {
        Button(action: {
            settings.applyPreset(preset)
            showPresetPicker = false
            if enableHaptics {
                HapticManager.shared.impact(style: .medium)
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Preset icon
                Image(systemName: preset.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.accentBlue)
                    .frame(width: 44, height: 44)

                // Preset details
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(DesignSystem.Typography.bodyLarge.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(preset.description)
                        .font(DesignSystem.Typography.captionLarge)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    // Visual representation of preset values
                    HStack(spacing: 2) {
                        ForEach(0..<6, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(DesignSystem.Colors.accentBlue.opacity(0.6))
                                .frame(width: 10, height: CGFloat(preset.values[index] / 100.0 * 30))
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer()

                // Checkmark if currently matches
                if isCurrentPreset(preset) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accentGreen)
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(DesignSystem.Colors.surface)
            )
            .applyShadows(DesignSystem.NeumorphicShadow.small())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func isCurrentPreset(_ preset: NeumorphicEqualizerSettings.Preset) -> Bool {
        let bands = NeumorphicEqualizerSettings.Band.allCases
        for (index, band) in bands.enumerated() {
            if index < preset.values.count {
                let currentValue = settings.getValue(for: band)
                let presetValue = preset.values[index]
                if abs(currentValue - presetValue) > 1.0 {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - Preview

#Preview("Equalizer Panel") {
    NeumorphicEqualizerPanel(settings: .constant(NeumorphicEqualizerSettings()))
        .padding()
        .background(DesignSystem.Colors.background)
}
