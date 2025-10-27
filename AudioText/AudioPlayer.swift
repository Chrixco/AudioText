import SwiftUI
import AVFoundation

/// Centralised audio playback controller with progress tracking and error reporting.
@MainActor
class AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentRecording: RecordingFile?
    @Published var playbackError: AudioError?
    @Published var playbackRate: Float = 1.0
    @Published private(set) var meterLevel: Float = 0

    private var audioPlayer: AVAudioPlayer?
#if os(iOS)
    private let audioSession = AVAudioSession.sharedInstance()
#endif
    private var timer: Timer?
    private var scrubContext: ScrubContext?

    override init() {
        super.init()
        setupSession()
    }

    private final class ScrubContext {
        let wasPlaying: Bool
        var previewTimer: Timer?

        init(wasPlaying: Bool) {
            self.wasPlaying = wasPlaying
        }
    }

    private func setupSession() {
#if os(iOS)
        do {
            try audioSession.setActive(true)
        } catch {
            playbackError = .audioSessionSetupFailed(error)
        }
#endif
    }

    func play(_ recording: RecordingFile) async {
        if isPlaying {
            await stop()
        }

        do {
            try beginPlayback(for: recording)
        } catch {
            playbackError = .playbackFailed(error)
        }
    }

    private func loadPlayer(for recording: RecordingFile) throws {
#if os(iOS)
        try audioSession.setActive(true)
#endif
        if let current = currentRecording, current.fileURL == recording.fileURL, audioPlayer != nil {
            duration = audioPlayer?.duration ?? 0
            return
        }

        audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.enableRate = true
        audioPlayer?.rate = playbackRate
        audioPlayer?.isMeteringEnabled = true
        currentRecording = recording
        duration = audioPlayer?.duration ?? 0
        currentTime = audioPlayer?.currentTime ?? 0
        playbackError = nil
    }

    private func beginPlayback(for recording: RecordingFile) throws {
        try loadPlayer(for: recording)

        audioPlayer?.rate = playbackRate
        audioPlayer?.currentTime = currentTime

        guard audioPlayer?.play() == true else {
            throw AudioError.playbackStartFailed
        }

        isPlaying = true
        startTimer()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }

    func stop() async {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentRecording = nil
        meterLevel = 0
        stopTimer()
        invalidatePreviewTimer()
        scrubContext = nil
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = max(0.5, min(2.0, rate))
        audioPlayer?.rate = playbackRate
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    func currentLevel() -> Float {
        meterLevel
    }

    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = self.audioPlayer?.currentTime ?? 0
                self.updateMeterLevel()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMeterLevel() {
        guard let player = audioPlayer, player.isPlaying else {
            meterLevel = max(0, meterLevel * 0.8)
            return
        }

        player.updateMeters()
        let power = player.averagePower(forChannel: 0)
        let level = pow(10, power / 20)
        meterLevel = max(0, min(1, level))
    }

    func beginInteractiveScrub(for recording: RecordingFile) {
        if scrubContext != nil {
            return
        }

        do {
            try loadPlayer(for: recording)
        } catch {
            playbackError = .playbackFailed(error)
            return
        }

        scrubContext = ScrubContext(wasPlaying: isPlaying)
        invalidatePreviewTimer()
        audioPlayer?.rate = playbackRate
        if !isPlaying {
            audioPlayer?.pause()
        }
    }

    func updateInteractiveScrub(progress: Double, velocity: Double) {
        guard let player = audioPlayer else { return }
        guard duration > 0 else { return }

        let clampedProgress = max(0, min(1, progress))
        let targetTime = duration * clampedProgress
        seek(to: targetTime)

        let velocityMagnitude = min(max(abs(velocity), 0), 3)
        let rate = Float(max(0.5, min(3.0, 1.0 + velocityMagnitude * 2.5)))
        player.rate = rate

        if scrubContext?.wasPlaying == true {
            if !isPlaying {
                isPlaying = true
                startTimer()
            }
            if player.isPlaying == false {
                player.play()
            }
        } else {
            startPreviewPlaybackIfNeeded()
            schedulePreviewStop(using: velocityMagnitude)
        }
    }

    func endInteractiveScrub() {
        guard let context = scrubContext else { return }
        invalidatePreviewTimer()
        audioPlayer?.rate = playbackRate

        if context.wasPlaying {
            if audioPlayer?.isPlaying == false {
                audioPlayer?.play()
            }
            isPlaying = true
            startTimer()
        } else {
            audioPlayer?.pause()
            audioPlayer?.currentTime = currentTime
            isPlaying = false
            stopTimer()
        }

        scrubContext = nil
    }

    private func startPreviewPlaybackIfNeeded() {
        guard let player = audioPlayer else { return }
        if !player.isPlaying {
            player.play()
        }
    }

    private func schedulePreviewStop(using velocity: Double) {
        guard let context = scrubContext, context.wasPlaying == false else { return }

        let clampedVelocity = min(max(velocity, 0), 3)
        let previewDuration = max(0.08, 0.25 - clampedVelocity * 0.05)

        invalidatePreviewTimer()

        context.previewTimer = Timer.scheduledTimer(withTimeInterval: previewDuration, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.audioPlayer?.pause()
            self.audioPlayer?.currentTime = self.currentTime
        }
    }

    private func invalidatePreviewTimer() {
        scrubContext?.previewTimer?.invalidate()
        scrubContext?.previewTimer = nil
    }
}

@MainActor
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        meterLevel = 0
        stopTimer()

        if !flag {
            playbackError = .playbackFailed(
                NSError(domain: "AudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Playback failed"])
            )
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        playbackError = .playbackFailed(error ?? NSError(domain: "AudioPlayer", code: -1))
        Task { await stop() }
    }
}
