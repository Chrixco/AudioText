import SwiftUI
import Speech
import AVFoundation
import Combine

private extension Notification.Name {
    static let speechRecognizerAvailabilityDidChange = Notification.Name("SFSpeechRecognizerAvailabilityDidChange")
}

/// Wrapper around `SFSpeechRecognizer` that exposes async transcription APIs and tracks availability.
@MainActor
class SpeechRecognizer: NSObject, ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionText = ""
    @Published var transcriptionError: SpeechError?
    @Published var permissionStatus: SpeechPermissionStatus = .unknown
    @Published var isAvailable = false
    @Published var useOnDeviceRecognition = false

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var liveRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var cancellables = Set<AnyCancellable>()

    var supportsOnDeviceRecognition: Bool {
        speechRecognizer?.supportsOnDeviceRecognition ?? false
    }

    override init() {
        super.init()
        setupSpeechRecognizer()
        refreshPermissions()
    }

    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        isAvailable = speechRecognizer?.isAvailable ?? false

        NotificationCenter.default.publisher(for: .speechRecognizerAvailabilityDidChange)
            .sink { [weak self] _ in
                self?.isAvailable = self?.speechRecognizer?.isAvailable ?? false
            }
            .store(in: &cancellables)
    }

    func refreshPermissions() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            permissionStatus = .granted
        case .denied:
            permissionStatus = .denied
        case .restricted:
            permissionStatus = .restricted
        case .notDetermined:
            permissionStatus = .notRequested
        @unknown default:
            permissionStatus = .unknown
        }
    }

    func requestPermissions() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authorizationStatus in
                continuation.resume(returning: authorizationStatus)
            }
        }
        switch status {
        case .authorized:
            permissionStatus = .granted
        case .denied:
            permissionStatus = .denied
        case .restricted:
            permissionStatus = .restricted
        case .notDetermined:
            permissionStatus = .notRequested
        @unknown default:
            permissionStatus = .unknown
        }
    }

    func transcribeAudio(from url: URL, language: String = "auto") async throws -> String {
        let recognizerForLanguage: SFSpeechRecognizer?
        if language != "auto" {
            recognizerForLanguage = SFSpeechRecognizer(locale: Locale(identifier: language))
        } else {
            recognizerForLanguage = speechRecognizer
        }

        guard let recognizer = recognizerForLanguage, recognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }

        if permissionStatus != .granted {
            await requestPermissions()
        }

        guard permissionStatus == .granted else {
            throw SpeechError.permissionDenied
        }

        isTranscribing = true
        transcriptionText = ""
        transcriptionError = nil
        defer { isTranscribing = false }

        do {
            let result = try await performTranscription(url: url, recognizer: recognizer)
            transcriptionText = result
            return result
        } catch {
            transcriptionError = .transcriptionFailed(error)
            throw error
        }
    }

    private func performTranscription(url: URL, recognizer: SFSpeechRecognizer) async throws -> String {
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        // Enable on-device recognition if supported and requested
        if useOnDeviceRecognition && recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let result {
                    let transcription = result.bestTranscription.formattedString
                    Task { @MainActor in
                        self?.transcriptionText = transcription
                    }
                    continuation.resume(returning: transcription)
                }
            }
        }
    }

    func startRealTimeTranscription() async throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }

        if permissionStatus != .granted {
            await requestPermissions()
        }

        guard permissionStatus == .granted else {
            throw SpeechError.permissionDenied
        }

        try await setupAudioEngine()

        isTranscribing = true
        transcriptionText = ""
        transcriptionError = nil
    }

    private func setupAudioEngine() async throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine else { throw SpeechError.audioEngineSetupFailed }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        // Enable on-device recognition if supported and requested
        if useOnDeviceRecognition, let recognizer = speechRecognizer, recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        liveRecognitionRequest = request

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.transcriptionText = result.bestTranscription.formattedString
                }

                if let error {
                    self?.transcriptionError = .transcriptionFailed(error)
                }
            }
        }
    }

    func stopRealTimeTranscription() {
        let node = audioEngine?.inputNode
        node?.removeTap(onBus: 0)
        liveRecognitionRequest?.endAudio()
        audioEngine?.stop()
        recognitionTask?.cancel()

        audioEngine = nil
        liveRecognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
    }

    func cancelTranscription() {
        liveRecognitionRequest?.endAudio()
        liveRecognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }
}

enum SpeechPermissionStatus {
    case unknown
    case notRequested
    case granted
    case denied
    case restricted
}

enum SpeechError: LocalizedError {
    case recognizerNotAvailable
    case permissionDenied
    case transcriptionFailed(Error)
    case audioEngineSetupFailed

    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognition is not available on this device."
        case .permissionDenied:
            return "Speech recognition permission is required."
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .audioEngineSetupFailed:
            return "Failed to configure the audio engine."
        }
    }
}
