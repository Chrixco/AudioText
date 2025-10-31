import SwiftUI
import Combine

struct AudioVisualizer: View {
    let isActive: Bool
    let levelProvider: () -> Float

    @State private var audioLevels: [Double] = Array(repeating: 0.0, count: 32)
    @State private var timerCancellable: AnyCancellable?

    let barCount = 32
    let barWidth: CGFloat = 10.0  // Increased from 8.0 for better visibility
    let maxBarHeight: CGFloat = 60.0

    var body: some View {
        HStack(spacing: 3) {  // Increased from 2 to 3
            ForEach(0..<barCount, id: \.self) { index in
                AudioBar(
                    height: audioLevels[index] * maxBarHeight,
                    width: barWidth
                )
            }
        }
        .frame(height: maxBarHeight + 8)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            if isActive {
                start()
            }
        }
        .onDisappear(perform: stop)
        .onChange(of: isActive) { _, active in
            active ? start() : stop()
        }
    }

    private func start() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateLevels(with: Double(levelProvider()))
            }
    }

    private func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil

        // Smoothly fall back to silence
        withAnimation(.easeOut(duration: 0.2)) {
            audioLevels = Array(repeating: 0.0, count: barCount)
        }
    }

    private func updateLevels(with newValue: Double) {
        let clamped = max(0, min(1, newValue))
        for i in 0..<barCount {
            let variation = sin(Double(i) * 0.1) * 0.3 + 0.7
            let adjusted = clamped * variation
            audioLevels[i] = audioLevels[i] * 0.7 + adjusted * 0.3
        }
    }
}

struct AudioBar: View {
    let height: CGFloat
    let width: CGFloat

    // VU meter style color zones
    private var barColor: LinearGradient {
        // Calculate the percentage of the bar that's filled
        let normalizedHeight = height / 60.0 // maxBarHeight

        if normalizedHeight < 0.6 {
            // Green zone (0-60%) - Apple green
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.accentGreen,
                    DesignSystem.Colors.accentGreen.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else if normalizedHeight < 0.85 {
            // Yellow zone (60-85%) - Apple yellow
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.accentYellow,
                    DesignSystem.Colors.accentYellow.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else if normalizedHeight < 0.95 {
            // Orange zone (85-95%) - Apple orange
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.accentOrange,
                    DesignSystem.Colors.accentOrange.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // Red zone (95-100%) - Apple red
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.error,
                    DesignSystem.Colors.error.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var body: some View {
        VStack {
            Spacer()

            Rectangle()
                .fill(barColor)
                .frame(width: width, height: max(height, 2))
                .cornerRadius(width / 2)
                .opacity(height > 2 ? 1.0 : 0.4)
        }
    }
}

#Preview {
    AudioVisualizer(isActive: true, levelProvider: { 0.5 })
        .frame(width: 300, height: 80)
        .background(Color.gray.opacity(0.1))
}
