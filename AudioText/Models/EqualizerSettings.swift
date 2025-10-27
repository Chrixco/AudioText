import Foundation

struct EqualizerSettings: Codable, Equatable {
    var lowShelfGain: Double
    var bassGain: Double
    var midGain: Double
    var presenceGain: Double
    var airGain: Double
    var preGain: Double

    static let flat = EqualizerSettings(
        lowShelfGain: 0,
        bassGain: 0,
        midGain: 0,
        presenceGain: 0,
        airGain: 0,
        preGain: 0
    )

    var isFlat: Bool {
        self == .flat
    }

    func value(for band: EqualizerBand) -> Double {
        switch band {
        case .lowShelf: return lowShelfGain
        case .bass: return bassGain
        case .mid: return midGain
        case .presence: return presenceGain
        case .air: return airGain
        case .preGain: return preGain
        }
    }

    mutating func setValue(_ value: Double, for band: EqualizerBand) {
        switch band {
        case .lowShelf: lowShelfGain = value
        case .bass: bassGain = value
        case .mid: midGain = value
        case .presence: presenceGain = value
        case .air: airGain = value
        case .preGain: preGain = value
        }
    }

    func formattedSummary() -> String {
        if isFlat {
            return "Flat"
        }

        let gains = [
            lowShelfGain,
            bassGain,
            midGain,
            presenceGain,
            airGain
        ]

        let significantAdjustments = gains.filter { abs($0) >= 1.0 }

        if significantAdjustments.isEmpty {
            return "Subtle adjustments"
        } else if significantAdjustments.count <= 2 {
            return "Targeted boost"
        } else {
            return "Full profile"
        }
    }
}

enum EqualizerBand: String, CaseIterable, Identifiable {
    case lowShelf
    case bass
    case mid
    case presence
    case air
    case preGain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lowShelf: return "Low Shelf"
        case .bass: return "Bass"
        case .mid: return "Mid"
        case .presence: return "Presence"
        case .air: return "Air"
        case .preGain: return "Output Gain"
        }
    }

    var frequencyLabel: String {
        switch self {
        case .lowShelf: return "60 Hz"
        case .bass: return "120 Hz"
        case .mid: return "1 kHz"
        case .presence: return "4 kHz"
        case .air: return "10 kHz"
        case .preGain: return "Global"
        }
    }

    var gainRange: ClosedRange<Double> {
        switch self {
        case .preGain:
            return -6...6
        default:
            return -12...12
        }
    }

    var step: Double {
        0.5
    }
}

enum EqualizerPreset: String, CaseIterable, Identifiable {
    case flat
    case vocalPresence
    case warmTape
    case broadcast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flat: return "Flat"
        case .vocalPresence: return "Vocal Presence"
        case .warmTape: return "Warm Tape"
        case .broadcast: return "Broadcast"
        }
    }

    var settings: EqualizerSettings {
        switch self {
        case .flat:
            return .flat
        case .vocalPresence:
            return EqualizerSettings(
                lowShelfGain: -1.5,
                bassGain: -0.5,
                midGain: 2.5,
                presenceGain: 3.0,
                airGain: 2.0,
                preGain: -1.0
            )
        case .warmTape:
            return EqualizerSettings(
                lowShelfGain: 2.5,
                bassGain: 1.5,
                midGain: 0.5,
                presenceGain: -1.0,
                airGain: 1.0,
                preGain: 0.0
            )
        case .broadcast:
            return EqualizerSettings(
                lowShelfGain: 1.5,
                bassGain: 1.0,
                midGain: 2.0,
                presenceGain: 2.0,
                airGain: 2.5,
                preGain: -1.0
            )
        }
    }
}
