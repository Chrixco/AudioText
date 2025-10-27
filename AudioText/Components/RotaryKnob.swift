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

    private let outerGradient = LinearGradient(
        colors: [.blue, .cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let inactiveGradient = LinearGradient(
        colors: [.gray.opacity(0.7), .gray.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @State private var lastDetentIndex: Int = 0
    @State private var isDragging = false
    @State private var lastScrubValue: Double?
    @State private var lastScrubTime: Date?

    private let detentSpacing: Double = 0.05
    private let minAngle: Double = -140
    private let maxAngle: Double = 140

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let angle = angle(for: value)
            let innerSize = size * 0.45
            let innerRadius = innerSize / 2

            ZStack {
                Circle()
                    .fill(isActive ? outerGradient : inactiveGradient)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: size * 0.04)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)

                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: size * 0.06)
                    .frame(width: size * 0.84, height: size * 0.84)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: size * 0.68, height: size * 0.68)

                RotationGuide()
                    .stroke(Color.white.opacity(0.75), lineWidth: size * 0.03)
                    .frame(width: size * 0.9, height: size * 0.9)
                    .rotationEffect(.degrees(angle))
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
                                .foregroundStyle(.white)
                        }

                        if let title = centerTitle, !title.isEmpty {
                            Text(title)
                                .font(.system(size: innerSize * 0.28, weight: .semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }

                        if let subtitle = centerSubtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: innerSize * 0.2, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, innerSize * 0.2)
                    .frame(width: innerSize, height: innerSize)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.25))
                    )
                }
                .buttonStyle(.plain)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let location = gesture.location
                        let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        let distance = hypot(location.x - centre.x, location.y - centre.y)

                        guard distance > innerRadius else { return }

                        isDragging = true
                        onEditingChanged(true)
                        updateValue(with: location, in: proxy, ignoringInnerRadius: innerRadius)
                    }
                    .onEnded { gesture in
                        defer {
                            isDragging = false
                            onEditingChanged(false)
                            notifyScrubDelta(oldValue: value, newValue: value, ended: true)
                        }

                        let location = gesture.location
                        let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        let distance = hypot(location.x - centre.x, location.y - centre.y)

                        guard distance > innerRadius else {
                            return
                        }

                        updateValue(with: location, in: proxy, ignoringInnerRadius: innerRadius)
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func updateValue(with location: CGPoint, in proxy: GeometryProxy, ignoringInnerRadius innerRadius: CGFloat? = nil) {
        let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
        let dx = location.x - centre.x
        let dy = centre.y - location.y
        let distance = hypot(dx, dy)

        if let innerRadius, distance < innerRadius {
            return
        }

        let vector = CGVector(dx: dx, dy: dy)
        let angle = atan2(vector.dy, vector.dx) * 180 / .pi
        let clampedAngle = max(min(angle, maxAngle), minAngle)
        let normalised = (clampedAngle - minAngle) / (maxAngle - minAngle)
        let oldValue = value
        value = max(0, min(1, normalised))
        processFeedbackIfNeeded(oldValue: oldValue)
        notifyScrubDelta(oldValue: oldValue, newValue: value, ended: false)
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

    private func angle(for value: Double) -> Double {
        let clamped = max(0, min(1, value))
        return minAngle + (maxAngle - minAngle) * clamped
    }

    private func processFeedbackIfNeeded(oldValue: Double) {
        let newDetent = Int(value / detentSpacing)
        if newDetent != lastDetentIndex {
            lastDetentIndex = newDetent
            triggerHaptics()
            if onScrubDelta == nil {
                playTickSound()
            }
        }
    }

    private func triggerHaptics() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
#endif
    }

    private func playTickSound() {
#if os(iOS)
        AudioServicesPlaySystemSound(1110)
#endif
    }

    private struct RotationGuide: Shape {
        func path(in rect: CGRect) -> Path {
            let radius = min(rect.width, rect.height) / 2
            let guideRadius = radius * 0.8
            var path = Path()

            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: guideRadius,
                startAngle: .degrees(-160),
                endAngle: .degrees(160),
                clockwise: false
            )

            let tickPositions: [Double] = [-150, -110, -70, -30, 30, 70, 110, 150]
            let tickRadius = guideRadius
            let dotSize = guideRadius * 0.12

            for position in tickPositions {
                let angle = Angle.degrees(position)
                let point = CGPoint(
                    x: rect.midX + tickRadius * CGFloat(cos(angle.radians)),
                    y: rect.midY + tickRadius * CGFloat(sin(angle.radians))
                )
                let dotRect = CGRect(
                    x: point.x - dotSize / 2,
                    y: point.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                path.addEllipse(in: dotRect)
            }

            return path
        }
    }
}
