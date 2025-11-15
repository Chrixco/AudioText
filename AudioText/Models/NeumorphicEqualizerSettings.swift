//
//  NeumorphicEqualizerSettings.swift
//  AudioText
//
//  Brand new 6-band equalizer settings model
//

import Foundation
import SwiftUI

/// 6-band equalizer with percentage-based controls
struct NeumorphicEqualizerSettings: Codable, Equatable {

    // MARK: - Band Values (0-100%)

    var bassValue: Double = 50.0        // 60Hz - Deep bass
    var lowMidValue: Double = 50.0      // 125Hz - Low-mid warmth
    var midValue: Double = 50.0         // 250Hz - Mid presence
    var highMidValue: Double = 50.0     // 500Hz - Upper-mid clarity
    var highValue: Double = 50.0        // 1kHz - High definition
    var presenceValue: Double = 50.0    // 2kHz - Presence/air

    // MARK: - Band Definition

    enum Band: String, CaseIterable, Identifiable {
        case bass = "Bass"
        case lowMid = "Low-Mid"
        case mid = "Mid"
        case highMid = "High-Mid"
        case high = "High"
        case presence = "Presence"

        var id: String { rawValue }

        var frequency: String {
            switch self {
            case .bass: return "60Hz"
            case .lowMid: return "125Hz"
            case .mid: return "250Hz"
            case .highMid: return "500Hz"
            case .high: return "1kHz"
            case .presence: return "2kHz"
            }
        }

        var icon: String {
            switch self {
            case .bass: return "waveform.path"
            case .lowMid: return "waveform.path.ecg"
            case .mid: return "waveform"
            case .highMid: return "waveform.path.badge.plus"
            case .high: return "waveform.badge.plus"
            case .presence: return "waveform.badge.magnifyingglass"
            }
        }

        var description: String {
            switch self {
            case .bass: return "Deep low-end"
            case .lowMid: return "Warmth & body"
            case .mid: return "Vocal presence"
            case .highMid: return "Clarity"
            case .high: return "Definition"
            case .presence: return "Air & sparkle"
            }
        }
    }

    // MARK: - Presets

    struct Preset: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let values: [Double] // 6 values for each band
        let description: String

        static let flat = Preset(
            name: "Flat",
            icon: "equal",
            values: [50, 50, 50, 50, 50, 50],
            description: "Neutral, no adjustments"
        )

        static let vocal = Preset(
            name: "Vocal",
            icon: "person.wave.2",
            values: [30, 40, 65, 70, 60, 75],
            description: "Enhanced speech clarity"
        )

        static let bassBoost = Preset(
            name: "Bass Boost",
            icon: "speaker.wave.3",
            values: [85, 75, 50, 45, 40, 35],
            description: "Deep low-end punch"
        )

        static let clarity = Preset(
            name: "Clarity",
            icon: "light.beacon.max",
            values: [35, 40, 55, 65, 75, 85],
            description: "Crisp high frequencies"
        )

        static let podcast = Preset(
            name: "Podcast",
            icon: "mic",
            values: [40, 50, 70, 65, 55, 50],
            description: "Optimized for voice"
        )

        static let allPresets: [Preset] = [
            .flat, .vocal, .bassBoost, .clarity, .podcast
        ]
    }

    // MARK: - Computed Properties

    var isFlat: Bool {
        return bassValue == 50 && lowMidValue == 50 && midValue == 50 &&
               highMidValue == 50 && highValue == 50 && presenceValue == 50
    }

    // MARK: - Helper Methods

    func getValue(for band: Band) -> Double {
        switch band {
        case .bass: return bassValue
        case .lowMid: return lowMidValue
        case .mid: return midValue
        case .highMid: return highMidValue
        case .high: return highValue
        case .presence: return presenceValue
        }
    }

    mutating func setValue(_ value: Double, for band: Band) {
        let clampedValue = min(max(value, 0), 100)
        switch band {
        case .bass: bassValue = clampedValue
        case .lowMid: lowMidValue = clampedValue
        case .mid: midValue = clampedValue
        case .highMid: highMidValue = clampedValue
        case .high: highValue = clampedValue
        case .presence: presenceValue = clampedValue
        }
    }

    func getPercentageString(for band: Band) -> String {
        let value = getValue(for: band)
        return String(format: "%.0f%%", value)
    }

    func getColor(for band: Band) -> Color {
        let value = getValue(for: band)
        if value < 33 {
            return DesignSystem.Colors.accentOrange  // Low/reduced
        } else if value < 67 {
            return DesignSystem.Colors.accentBlue    // Neutral
        } else {
            return DesignSystem.Colors.accentGreen   // Boosted
        }
    }

    mutating func applyPreset(_ preset: Preset) {
        let bands = Band.allCases
        for (index, band) in bands.enumerated() {
            if index < preset.values.count {
                setValue(preset.values[index], for: band)
            }
        }
    }

    mutating func reset() {
        applyPreset(.flat)
    }
}
