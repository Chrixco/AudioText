import SwiftUI
#if os(iOS)
import AudioToolbox
#endif

/// Large neumorphic rotary play button with integrated scrubbing
/// Combines play/pause functionality with timeline scrubbing via rotation
struct NeumorphicRotaryPlayButton: View {
    @Binding var progress: Double  // 0.0 to 1.0
    var isPlaying: Bool
    var onPlayPause: () -> Void
    var onScrub: ((Double) -> Void)? = nil
    var centerTitle: String? = nil
    var centerSubtitle: String? = nil

    @State private var isDragging = false
    @State private var lastAngle: Double? = nil
    @State private var cumulativeRotation: Double = 0
    @State private var lastDetentIndex: Int = 0
    @State private var lastExternalProgress: Double = 0

    private let buttonSize: CGFloat = 220  // Large, hero size
    private let detentSpacing: Double = 0.01  // Fine haptic detents
    private let totalRotationDegrees: Double = 720  // 2 full rotations
    private let numberOfProgressDots = 32  // Progress indicators

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let innerSize = size * 0.55  // Larger center button
            let visualAngle = progress * totalRotationDegrees

            ZStack {
                // MARK: - Outer Circle (Embossed Base)
                Circle()
                    .fill(DesignSystem.Colors.buttonGradient)
                    .applyShadows(DesignSystem.NeumorphicShadow.largeEmbossed())

                // MARK: - Middle Ring (Highlight)
                Circle()
                    .stroke(DesignSystem.Colors.highlightLight, lineWidth: size * 0.05)
                    .frame(width: size * 0.86, height: size * 0.86)

                // MARK: - Progress Ring Track (Behind progress)
                Circle()
                    .stroke(
                        DesignSystem.Colors.textTertiary.opacity(0.15),
                        style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round)
                    )
                    .frame(width: size * 0.92, height: size * 0.92)

                // MARK: - Progress Ring (Active)
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: min(1, progress))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.accentBlue.opacity(0.8),
                                    DesignSystem.Colors.accentCyan.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round)
                        )
                        .frame(width: size * 0.92, height: size * 0.92)
                        .rotationEffect(.degrees(-90))  // Start at top
                        .animation(.easeOut(duration: 0.2), value: progress)
                }

                // MARK: - Progress Dots
                ProgressDotsRing(
                    progress: progress,
                    numberOfDots: numberOfProgressDots,
                    size: size,
                    isPlaying: isPlaying
                )
                .rotationEffect(.degrees(visualAngle))

                // MARK: - Inner Circle Background (Debossed)
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: size * 0.70, height: size * 0.70)
                    .applyShadows(DesignSystem.NeumorphicShadow.deepDebossed())

                // MARK: - Play/Pause Button (Center)
                Button(action: {
                    guard !isDragging else { return }
                    triggerHaptics()
                    onPlayPause()
                }) {
                    VStack(spacing: 8) {
                        // Play/Pause Icon
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: innerSize * 0.35, weight: .semibold))
                            .foregroundStyle(isPlaying ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.textSecondary)
                            .offset(x: isPlaying ? 0 : 3)  // Optical centering for play icon

                        // Title
                        if let title = centerTitle, !title.isEmpty {
                            Text(title)
                                .font(.system(size: innerSize * 0.16, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        // Subtitle
                        if let subtitle = centerSubtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: innerSize * 0.12, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.horizontal, innerSize * 0.15)
                    .frame(width: innerSize, height: innerSize)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                Circle()
                                    .strokeBorder(DesignSystem.Colors.highlightLight.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(isDragging ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                .animation(.easeInOut(duration: 0.3), value: isPlaying)
            }
            .contentShape(Circle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { gesture in
                        handleDragChanged(gesture: gesture, in: proxy)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: buttonSize, height: buttonSize)
        .onChange(of: progress) { oldValue, newValue in
            // Sync cumulative rotation when progress changes externally (not during drag)
            if !isDragging && abs(newValue - lastExternalProgress) > 0.001 {
                cumulativeRotation = newValue * totalRotationDegrees
                lastExternalProgress = newValue
            }
        }
        .onAppear {
            cumulativeRotation = progress * totalRotationDegrees
            lastExternalProgress = progress
        }
    }

    // MARK: - Gesture Handlers

    private func handleDragChanged(gesture: DragGesture.Value, in proxy: GeometryProxy) {
        if !isDragging {
            isDragging = true
            // Sync cumulative rotation with current progress when starting drag
            cumulativeRotation = progress * totalRotationDegrees
        }

        let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
        let dx = gesture.location.x - centre.x
        let dy = gesture.location.y - centre.y

        let currentAngle = atan2(dy, dx) * 180 / .pi  // -180 to 180

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

        // Convert cumulative rotation to progress (0-1)
        let newProgress = cumulativeRotation / totalRotationDegrees
        let oldProgress = progress

        progress = newProgress
        lastExternalProgress = newProgress

        // Trigger haptics on detent crossing
        processFeedbackIfNeeded(oldValue: oldProgress)

        // Notify scrub callback
        if let onScrub = onScrub {
            onScrub(newProgress)
        }
    }

    private func handleDragEnded() {
        isDragging = false
        lastAngle = nil
    }

    // MARK: - Haptic Feedback

    private func processFeedbackIfNeeded(oldValue: Double) {
        let newDetent = Int(progress / detentSpacing)
        if newDetent != lastDetentIndex {
            lastDetentIndex = newDetent
            triggerHaptics()
        }
    }

    private func triggerHaptics() {
        HapticManager.shared.selection()
    }
}

// MARK: - Progress Dots Ring

private struct ProgressDotsRing: View {
    let progress: Double
    let numberOfDots: Int
    let size: CGFloat
    let isPlaying: Bool

    var body: some View {
        ZStack {
            ForEach(0..<numberOfDots, id: \.self) { index in
                ProgressDot(
                    index: index,
                    totalDots: numberOfDots,
                    progress: progress,
                    size: size,
                    isPlaying: isPlaying
                )
            }
        }
    }
}

private struct ProgressDot: View {
    let index: Int
    let totalDots: Int
    let progress: Double
    let size: CGFloat
    let isPlaying: Bool

    private var angle: Angle {
        Angle.degrees(Double(index) * 360.0 / Double(totalDots) - 90)  // Start at top
    }

    private var radius: CGFloat {
        size * 0.46  // Position on outer ring
    }

    private var dotSize: CGFloat {
        let progressDots = Int(progress * Double(totalDots * 2))  // *2 because 2 rotations
        let dotIndex = index
        let firstLapFilled = progressDots > dotIndex
        let secondLapFilled = progressDots > (dotIndex + totalDots)

        // Larger if in progress range
        if (firstLapFilled && !secondLapFilled) || secondLapFilled {
            return size * 0.025
        } else {
            return size * 0.015
        }
    }

    private var dotColor: Color {
        let progressDots = Int(progress * Double(totalDots * 2))
        let dotIndex = index
        let firstLapFilled = progressDots > dotIndex
        let secondLapFilled = progressDots > (dotIndex + totalDots)

        if secondLapFilled || firstLapFilled {
            return isPlaying ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.accentBlue.opacity(0.6)
        } else {
            return DesignSystem.Colors.textTertiary.opacity(0.3)
        }
    }

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: dotSize, height: dotSize)
            .offset(y: -radius)
            .rotationEffect(angle)
            .animation(.easeOut(duration: 0.15), value: dotColor)
    }
}

// MARK: - View Extension for Multi-Layer Shadows

private extension View {
    @ViewBuilder
    func applyShadows(_ shadows: [(Color, CGFloat, CGFloat, CGFloat)]) -> some View {
        var view = AnyView(self)
        for (color, radius, x, y) in shadows {
            view = AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
        }
        view
    }
}

// MARK: - Preview

#Preview("Rotary Play Button") {
    VStack(spacing: 40) {
        // Playing state
        NeumorphicRotaryPlayButton(
            progress: .constant(0.35),
            isPlaying: true,
            onPlayPause: {},
            centerTitle: "2:14",
            centerSubtitle: "6:12"
        )

        // Paused state
        NeumorphicRotaryPlayButton(
            progress: .constant(0.65),
            isPlaying: false,
            onPlayPause: {},
            centerTitle: "4:01",
            centerSubtitle: "6:12"
        )
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
}
