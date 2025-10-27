import SwiftUI
import Combine

struct AudioVisualizer: View {
    let isActive: Bool
    let levelProvider: () -> Float

    @State private var audioLevels: [Double] = Array(repeating: 0.0, count: 32)
    @State private var timerCancellable: AnyCancellable?

    let barCount = 32
    let barWidth: CGFloat = 8.0
    let maxBarHeight: CGFloat = 60.0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                AudioBar(
                    height: audioLevels[index] * maxBarHeight,
                    width: barWidth
                )
            }
        }
        .frame(height: maxBarHeight + 10)
        .padding()
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
    
    var body: some View {
        VStack {
            Spacer()
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.9),
                            Color.cyan.opacity(0.7),
                            Color.blue.opacity(0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
