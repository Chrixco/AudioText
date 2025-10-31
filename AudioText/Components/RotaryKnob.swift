import SwiftUI
#if os(iOS)
import AudioToolbox
#endif

struct RotaryKnob: View {
    @Binding var value: Double
    var isActive: Bool
    var onEditingChanged: (Bool) -> Void
    var onTap: () -> Void
    var centerIcon: String? = nil
    var centerTitle: String? = nil
    var centerSubtitle: String? = nil
    var onScrubDelta: ((Double, TimeInterval, Bool) -> Void)? = nil

    // Both active and inactive use background color for neumorphic effect
    private let outerGradient = DesignSystem.Colors.buttonGradient
    private let inactiveGradient = DesignSystem.Colors.buttonGradient

    @State private var lastDetentIndex: Int = 0
    @State private var isDragging = false
    @State private var lastScrubValue: Double?
    @State private var lastScrubTime: Date?
    @State private var dragStartLocation: CGPoint?
    @State private var cumulativeRotation: Double = 0  // Track total rotation in degrees
    @State private var lastAngle: Double? = nil  // Track previous angle to detect boundary crossing
    @State private var lastExternalValue: Double = 0  // Track last value set from binding

    private let detentSpacing: Double = 0.02  // Finer detents for smoother haptics
    private let totalRotationDegrees: Double = 720  // 2 full rotations for entire timeline

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let innerSize = size * 0.45
            let innerRadius = innerSize / 2
            let visualAngle = visualRotationAngle(for: value)

            ZStack {
                // Outer circle with soft neumorphic depth (reference style)
                Circle()
                    .fill(outerGradient)
                    .shadow(color: DesignSystem.Colors.shadowLight, radius: 12, x: -5, y: -5)
                    .shadow(color: DesignSystem.Colors.shadowDark, radius: 14, x: 6, y: 6)

                // Middle ring
                Circle()
                    .stroke(DesignSystem.Colors.highlightLight, lineWidth: size * 0.06)
                    .frame(width: size * 0.84, height: size * 0.84)

                // Inner circle background (soft debossed - reference style)
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: size * 0.68, height: size * 0.68)
                    .shadow(color: DesignSystem.Colors.shadowDark, radius: 10, x: 4, y: 4)
                    .shadow(color: DesignSystem.Colors.shadowLight, radius: 8, x: -3, y: -3)

                RotationGuide(progress: value)
                    .stroke(DesignSystem.Colors.textPrimary.opacity(0.75), lineWidth: size * 0.03)
                    .frame(width: size * 0.9, height: size * 0.9)
                    .rotationEffect(.degrees(visualAngle))
                    .blur(radius: isActive ? 0 : 3)

                Button(action: {
                    guard !isDragging else { return }
                    triggerHaptics()
                    playTickSound()
                    onTap()
                }) {
                    VStack(spacing: 6) {
                        if let icon = centerIcon {
                            Image(systemName: icon)
                                .font(.system(size: innerSize * 0.45, weight: .semibold))
                                .foregroundStyle(isActive ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textSecondary)
                        }

                        if let title = centerTitle, !title.isEmpty {
                            Text(title)
                                .font(.system(size: innerSize * 0.28, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                        }

                        if let subtitle = centerSubtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: innerSize * 0.2, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, innerSize * 0.2)
                    .frame(width: innerSize, height: innerSize)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                Circle()
                                    .strokeBorder(DesignSystem.Colors.highlightLight, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .contentShape(Circle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { gesture in
                        let location = gesture.location
                        let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        let distance = hypot(location.x - centre.x, location.y - centre.y)

                        // Only start if we begin inside the knob, but track it if drag is ongoing
                        if !isDragging {
                            guard distance > innerRadius else { return }
                            dragStartLocation = location
                            isDragging = true
                            // Sync cumulative rotation with current value when starting drag
                            cumulativeRotation = value * totalRotationDegrees
                            onEditingChanged(true)
                        }

                        // Once dragging, allow rotation even if finger moves outside
                        updateValue(with: location, in: proxy, allowOutside: true)
                    }
                    .onEnded { gesture in
                        let location = gesture.location
                        updateValue(with: location, in: proxy, allowOutside: true)

                        defer {
                            isDragging = false
                            dragStartLocation = nil
                            lastAngle = nil
                            lastExternalValue = value  // Sync tracking with final value
                            onEditingChanged(false)
                            notifyScrubDelta(oldValue: value, newValue: value, ended: true)
                        }
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: value) { oldValue, newValue in
            // Sync cumulative rotation when value changes externally (not during drag)
            if !isDragging && abs(newValue - lastExternalValue) > 0.001 {
                cumulativeRotation = newValue * totalRotationDegrees
                lastExternalValue = newValue
            }
        }
        .onAppear {
            // Initialize cumulative rotation and tracking on appear
            cumulativeRotation = value * totalRotationDegrees
            lastExternalValue = value
        }
    }

    private func updateValue(with location: CGPoint, in proxy: GeometryProxy, allowOutside: Bool = false) {
        let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
        let dx = location.x - centre.x
        let dy = location.y - centre.y

        let vector = CGVector(dx: dx, dy: dy)
        let currentAngle = atan2(vector.dy, vector.dx) * 180 / .pi  // -180 to 180

        // Detect boundary crossing and accumulate rotation
        if let previousAngle = lastAngle {
            var delta = currentAngle - previousAngle

            // Detect crossing the -180°/180° boundary
            if delta > 180 {
                delta -= 360  // Crossed from 180 to -180 (counterclockwise)
            } else if delta < -180 {
                delta += 360  // Crossed from -180 to 180 (clockwise)
            }

            cumulativeRotation += delta
        }

        lastAngle = currentAngle

        // Clamp cumulative rotation to 0-720 degrees
        cumulativeRotation = max(0, min(totalRotationDegrees, cumulativeRotation))

        // Convert cumulative rotation to value (0-1)
        let oldValue = value
        let newValue = cumulativeRotation / totalRotationDegrees
        value = newValue
        lastExternalValue = newValue  // Update tracking to prevent onChange from firing

        processFeedbackIfNeeded(oldValue: oldValue)
        notifyScrubDelta(oldValue: oldValue, newValue: newValue, ended: false)
    }

    private func notifyScrubDelta(oldValue: Double, newValue: Double, ended: Bool) {
        guard let onScrubDelta else {
            if ended {
                lastScrubValue = nil
                lastScrubTime = nil
            }
            return
        }

        let now = Date()

        if ended {
            if let lastValue = lastScrubValue, let lastTime = lastScrubTime {
                let delta = newValue - lastValue
                let interval = now.timeIntervalSince(lastTime)
                onScrubDelta(delta, interval, true)
            } else {
                onScrubDelta(0, 0, true)
            }
            lastScrubValue = nil
            lastScrubTime = nil
            return
        }

        let referenceValue = lastScrubValue ?? oldValue
        let referenceTime = lastScrubTime ?? now
        let interval = max(now.timeIntervalSince(referenceTime), 0.001)
        let delta = newValue - referenceValue
        onScrubDelta(delta, interval, false)

        lastScrubValue = newValue
        lastScrubTime = now
    }

    private func visualRotationAngle(for value: Double) -> Double {
        let clamped = max(0, min(1, value))
        return clamped * totalRotationDegrees  // 0-720 degrees
    }

    private func processFeedbackIfNeeded(oldValue: Double) {
        let newDetent = Int(value / detentSpacing)
        if newDetent != lastDetentIndex {
            lastDetentIndex = newDetent
            triggerHaptics()
            // Only play sound on significant movements, not every detent
            let significantMove = abs(value - oldValue) > 0.05
            if onScrubDelta == nil && significantMove {
                playTickSound()
            }
        }
    }

    private func triggerHaptics() {
        // Use HapticManager for consistent, high-quality haptics
        HapticManager.shared.selection()
    }

    private func playTickSound() {
#if os(iOS)
        AudioServicesPlaySystemSound(1110)
#endif
    }

    private struct RotationGuide: Shape {
        let progress: Double

        func path(in rect: CGRect) -> Path {
            let radius = min(rect.width, rect.height) / 2
            let guideRadius = radius * 0.8
            var path = Path()

            // Draw full circle guide
            path.addEllipse(in: CGRect(
                x: rect.midX - guideRadius,
                y: rect.midY - guideRadius,
                width: guideRadius * 2,
                height: guideRadius * 2
            ))

            // Add progress indicators - 16 dots around the circle (representing 45° increments)
            let numberOfDots = 16
            let dotSize = guideRadius * 0.08
            let progressDots = Int(progress * Double(numberOfDots * 2))  // *2 because we do 2 rotations

            for i in 0..<numberOfDots {
                let angle = Angle.degrees(Double(i) * 360.0 / Double(numberOfDots) - 90)  // Start at top
                let point = CGPoint(
                    x: rect.midX + guideRadius * CGFloat(cos(angle.radians)),
                    y: rect.midY + guideRadius * CGFloat(sin(angle.radians))
                )

                // Calculate if this dot should be filled based on progress through 2 rotations
                let dotIndex = i
                let firstLapFilled = progressDots > dotIndex
                let secondLapFilled = progressDots > (dotIndex + numberOfDots)

                // Draw larger dot if this represents current progress
                let size = (firstLapFilled && !secondLapFilled) || secondLapFilled ? dotSize * 1.5 : dotSize

                let dotRect = CGRect(
                    x: point.x - size / 2,
                    y: point.y - size / 2,
                    width: size,
                    height: size
                )
                path.addEllipse(in: dotRect)
            }

            return path
        }
    }
}
