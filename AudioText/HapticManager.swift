import UIKit

#if os(iOS)
/// Manages haptic feedback for the app
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback

    /// Light impact - for subtle interactions
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact - for standard interactions
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact - for important actions
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Soft impact (iOS 13+) - very subtle
    @available(iOS 13.0, *)
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid impact (iOS 13+) - firm feedback
    @available(iOS 13.0, *)
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    // MARK: - Selection Feedback

    /// Selection changed - for picker/slider interactions
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Notification Feedback

    /// Success feedback - for completed actions
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning feedback - for cautionary actions
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error feedback - for failed actions
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Custom Patterns

    /// Play/Pause toggle haptic
    func playPauseToggle() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
    }

    /// Recording start haptic
    func recordingStart() {
        heavy()
    }

    /// Recording stop haptic
    func recordingStop() {
        medium()
    }

    /// Equalizer adjustment haptic
    func equalizerAdjust() {
        if #available(iOS 13.0, *) {
            rigid()
        } else {
            light()
        }
    }

    /// Delete/destructive action haptic
    func destructiveAction() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Button tap haptic
    func buttonTap() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
    }
}
#else
// macOS placeholder - no haptics
class HapticManager {
    static let shared = HapticManager()
    private init() {}

    func light() {}
    func medium() {}
    func heavy() {}
    func selection() {}
    func success() {}
    func warning() {}
    func error() {}
    func playPauseToggle() {}
    func recordingStart() {}
    func recordingStop() {}
    func equalizerAdjust() {}
    func destructiveAction() {}
    func buttonTap() {}
}
#endif
