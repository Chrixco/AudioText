import SwiftUI
import AVFoundation
#if os(iOS)
import MediaPlayer
#endif

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
        setupRemoteControls()
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
            // Configure for playback and background audio
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("✅ Audio session configured for background playback")
        } catch {
            playbackError = .audioSessionSetupFailed(error)
            print("❌ Audio session setup failed: \(error)")
        }
#endif
    }

    // MARK: - Remote Controls & Now Playing

    private func setupRemoteControls() {
#if os(iOS)
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.resume()
                HapticManager.shared.playPauseToggle()
            }
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.pause()
                HapticManager.shared.playPauseToggle()
            }
            return .success
        }

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.isPlaying {
                    self.pause()
                } else {
                    self.resume()
                }
                HapticManager.shared.playPauseToggle()
            }
            return .success
        }

        // Skip forward/backward
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self,
                      let skipEvent = event as? MPSkipIntervalCommandEvent else { return }
                let newTime = min(self.duration, self.currentTime + skipEvent.interval)
                self.seek(to: newTime)
                HapticManager.shared.selection()
            }
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self,
                      let skipEvent = event as? MPSkipIntervalCommandEvent else { return }
                let newTime = max(0, self.currentTime - skipEvent.interval)
                self.seek(to: newTime)
                HapticManager.shared.selection()
            }
            return .success
        }

        // Seek command
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self,
                      let seekEvent = event as? MPChangePlaybackPositionCommandEvent else { return }
                self.seek(to: seekEvent.positionTime)
            }
            return .success
        }

        print("✅ Remote controls configured")
#endif
    }

    private func updateNowPlayingInfo() {
#if os(iOS)
        guard let recording = currentRecording else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = [String: Any]()

        // Title and artist
        let fileName = recording.fileName.replacingOccurrences(of: ".m4a", with: "")
        nowPlayingInfo[MPMediaItemPropertyTitle] = fileName
        nowPlayingInfo[MPMediaItemPropertyArtist] = "AudioText"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Recordings"

        // Duration and current time
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0

        // Metadata
        if let transcript = recording.transcript, !transcript.isEmpty {
            nowPlayingInfo[MPMediaItemPropertyComments] = String(transcript.prefix(100))
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("✅ Now Playing info updated: \(fileName)")
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
        HapticManager.shared.playPauseToggle()
        updateNowPlayingInfo()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
        HapticManager.shared.playPauseToggle()
        updateNowPlayingInfo()
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
        HapticManager.shared.playPauseToggle()
        updateNowPlayingInfo()
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
