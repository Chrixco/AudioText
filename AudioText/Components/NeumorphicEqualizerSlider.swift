//
//  NeumorphicEqualizerSlider.swift
//  AudioText
//
//  Beautiful neumorphic vertical equalizer slider with percentage display
//

import SwiftUI
import UIKit

struct NeumorphicEqualizerSlider: View {

    // MARK: - Properties

    let band: NeumorphicEqualizerSettings.Band
    @Binding var value: Double // 0-100
    let enableHaptics: Bool

    @State private var lastHapticValue: Double = 0
    @State private var isDragging: Bool = false

    // MARK: - Constants

    private let sliderHeight: CGFloat = 180
    private let sliderWidth: CGFloat = 36
    private let thumbSize: CGFloat = 28
    private let cornerRadius: CGFloat = 18

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xSmall) {
            // Percentage display
            Text(String(format: "%.0f%%", value))
                .font(DesignSystem.Typography.bodyMedium.weight(.semibold))
                .foregroundStyle(colorForValue)
                .monospacedDigit()
                .frame(width: 55, height: 22)
                .animation(.easeInOut(duration: 0.2), value: value)

            // Vertical slider
            ZStack(alignment: .bottom) {
                // Background track (debossed)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DesignSystem.Colors.surfaceDepressed)
                    .frame(width: sliderWidth, height: sliderHeight)
                    .applyShadows(DesignSystem.NeumorphicShadow.mediumDebossed())

                // Filled portion with gradient
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColorsForValue,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: sliderWidth, height: filledHeight)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)

                // Thumb indicator (embossed)
                Circle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: thumbSize, height: thumbSize)
                    .applyShadows(isDragging ? DesignSystem.NeumorphicShadow.smallEmbossed() : DesignSystem.NeumorphicShadow.mediumEmbossed())
                    .overlay(
                        Circle()
                            .strokeBorder(colorForValue, lineWidth: isDragging ? 3 : 2)
                            .animation(.easeInOut(duration: 0.2), value: isDragging)
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .offset(y: -thumbOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        updateValue(from: gesture.location)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )

            // Band label and frequency
            VStack(spacing: DesignSystem.Spacing.xxxSmall) {
                Text(band.rawValue)
                    .font(DesignSystem.Typography.captionLarge.weight(.medium))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(band.frequency)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(width: 70)
        }
    }

    // MARK: - Computed Properties

    private var filledHeight: CGFloat {
        return (value / 100.0) * sliderHeight
    }

    private var thumbOffset: CGFloat {
        return (value / 100.0) * sliderHeight
    }

    private var colorForValue: Color {
        if value < 33 {
            return DesignSystem.Colors.accentOrange  // Low
        } else if value < 67 {
            return DesignSystem.Colors.accentBlue    // Neutral
        } else {
            return DesignSystem.Colors.accentGreen   // Boosted
        }
    }

    private var gradientColorsForValue: [Color] {
        if value < 33 {
            return [
                DesignSystem.Colors.accentOrange.opacity(0.3),
                DesignSystem.Colors.accentOrange.opacity(0.6)
            ]
        } else if value < 67 {
            return [
                DesignSystem.Colors.accentBlue.opacity(0.3),
                DesignSystem.Colors.accentBlue.opacity(0.6)
            ]
        } else {
            return [
                DesignSystem.Colors.accentGreen.opacity(0.3),
                DesignSystem.Colors.accentGreen.opacity(0.6)
            ]
        }
    }

    // MARK: - Methods

    private func updateValue(from location: CGPoint) {
        // Calculate percentage from bottom (0) to top (100)
        let percentage = max(0, min(100, 100 - (location.y / sliderHeight * 100)))

        // Update value
        value = percentage

        // Trigger haptic feedback every 10% change
        if enableHaptics {
            let roundedValue = round(percentage / 10) * 10
            if roundedValue != lastHapticValue {
                HapticManager.shared.selection()
                lastHapticValue = roundedValue
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Slider") {
    NeumorphicEqualizerSlider(
        band: .bass,
        value: .constant(65),
        enableHaptics: true
    )
    .padding()
    .background(DesignSystem.Colors.background)
}

#Preview("All Sliders") {
    HStack(spacing: DesignSystem.Spacing.medium) {
        ForEach(NeumorphicEqualizerSettings.Band.allCases) { band in
            NeumorphicEqualizerSlider(
                band: band,
                value: .constant(Double.random(in: 20...80)),
                enableHaptics: true
            )
        }
    }
    .padding()
    .background(DesignSystem.Colors.background)
}
