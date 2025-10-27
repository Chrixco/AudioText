import SwiftUI
import AVFoundation
import Combine
#if os(iOS)
enum AudioInputMode: String, CaseIterable, Identifiable {
    case builtIn
    case external
    case automatic

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .builtIn: return "mic.fill"
        case .external: return "headphones"
        case .automatic: return "dot.radiowaves.left.and.right"
        }
    }

    var title: String {
        switch self {
        case .builtIn: return "Mic"
        case .external: return "Device"
        case .automatic: return "Auto"
        }
    }
}
#endif

/// Modernised audio recorder that handles permission management, error surfacing,
/// and persistent storage of captured clips.
@MainActor
class AudioRecorder: NSObject, ObservableObject {
    // MARK: Published state
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordings: [RecordingFile] = []
    @Published var recordingError: AudioError?
    @Published var permissionStatus: PermissionStatus = .unknown

    // MARK: Private members
    private var audioRecorder: AVAudioRecorder?
#if os(iOS)
    private let audioSession = AVAudioSession.sharedInstance()
    private let audioSessionCategory: AVAudioSession.Category = .playAndRecord
    private let audioSessionMode: AVAudioSession.Mode = .default
    private let audioSessionOptions: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
    @Published var inputMode: AudioInputMode = .automatic
    @Published private(set) var isBluetoothAvailable = false
    @Published private(set) var isExternalInputAvailable = false
    private var routeChangeObserver: NSObjectProtocol?
#endif
    private var timer: Timer?
    private var currentRecordingURL: URL?
    private let metadataStore = RecordingMetadataStore()
    private var metadata: [String: RecordingMetadata] = [:]

    // Recording settings tuned for speech
    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 128000
    ]

    override init() {
        super.init()
        metadata = metadataStore.load()
        setupAudioSession()
        loadRecordings()
        refreshPermissions()
#if os(iOS)
        updateAvailableInputs()
        routeChangeObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleRouteChange()
        }
#endif
    }

#if os(iOS)
    deinit {
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
#endif

    // MARK: Permission handling
    func refreshPermissions() {
#if os(iOS)
        switch audioSession.recordPermission {
        case .granted:
            permissionStatus = .granted
        case .denied:
            permissionStatus = .denied
        case .undetermined:
            permissionStatus = .notRequested
        @unknown default:
            permissionStatus = .unknown
        }
#else
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            permissionStatus = .granted
        case .denied:
            permissionStatus = .denied
        case .restricted:
            permissionStatus = .denied
        case .notDetermined:
            permissionStatus = .notRequested
        @unknown default:
            permissionStatus = .unknown
        }
#endif
    }

    @discardableResult
    func requestPermissions() async -> Bool {
#if os(iOS)
        let granted = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
#else
        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { allowed in
                continuation.resume(returning: allowed)
            }
        }
#endif
        permissionStatus = granted ? .granted : .denied
        return granted
    }

    // MARK: Recording lifecycle
    func startRecording() async {
        guard !isRecording else { return }

        if permissionStatus != .granted {
            let granted = await requestPermissions()
            guard granted else {
                recordingError = .permissionDenied
                return
            }
        }

        guard permissionStatus == .granted else {
            recordingError = .permissionDenied
            return
        }

        do {
            try beginRecording()
        } catch {
            recordingError = .recordingFailed(error)
        }
    }

    private func beginRecording() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        currentRecordingURL = fileURL

        try configureSessionForRecording()

#if os(iOS)
        applyInputMode()
#endif

        audioRecorder = try AVAudioRecorder(url: fileURL, settings: recordingSettings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true

        guard audioRecorder?.record() == true else {
            throw AudioError.recordingStartFailed
        }

        isRecording = true
        recordingTime = 0
        recordingError = nil

        startTimer()
    }

    /// Stops the current recording and returns the saved file when available.
    @discardableResult
    func stopRecording() -> RecordingFile? {
        guard isRecording else { return nil }

        audioRecorder?.stop()
        audioRecorder = nil
        stopTimer()

        isRecording = false

        defer {
            currentRecordingURL = nil
            recordingTime = 0
        }

        guard let url = currentRecordingURL else { return nil }

        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
        let fileSize = Int64(resourceValues?.fileSize ?? 0)
        let creationDate = resourceValues?.creationDate ?? Date()
        let fileName = url.lastPathComponent

        let recording = RecordingFile(
            fileName: fileName,
            fileURL: url,
            duration: recordingTime,
            dateCreated: creationDate,
            fileSize: fileSize,
            transcript: metadata[fileName]?.transcript
        )

        recordings.append(recording)
        recordings.sort { $0.dateCreated > $1.dateCreated }
        var entry = metadata[fileName] ?? RecordingMetadata()
        entry.transcript = recording.transcript
        metadata[fileName] = entry
        metadataStore.save(metadata)
        return recording
    }

    func deleteRecording(_ recording: RecordingFile) {
        do {
            try FileManager.default.removeItem(at: recording.fileURL)
            recordings.removeAll { $0.id == recording.id }
            metadata.removeValue(forKey: recording.fileName)
            metadataStore.save(metadata)
        } catch {
            recordingError = .fileOperationFailed(error)
        }
    }

    func renameRecording(_ recording: RecordingFile, to newName: String) throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate new name
        guard !trimmedName.isEmpty else {
            throw AudioError.invalidFileName("Name cannot be empty")
        }

        // Sanitize filename (remove invalid characters)
        let sanitizedName = sanitizeFileName(trimmedName)
        guard !sanitizedName.isEmpty else {
            throw AudioError.invalidFileName("Name contains only invalid characters")
        }

        // Ensure .m4a extension
        let newFileName = sanitizedName.hasSuffix(".m4a") ? sanitizedName : "\(sanitizedName).m4a"

        // Check for duplicate
        guard !recordings.contains(where: { $0.fileName == newFileName && $0.id != recording.id }) else {
            throw AudioError.duplicateFileName(newFileName)
        }

        // Construct new URL
        let newURL = recording.fileURL.deletingLastPathComponent().appendingPathComponent(newFileName)

        // Rename the file
        do {
            try FileManager.default.moveItem(at: recording.fileURL, to: newURL)

            // Update metadata (transfer old metadata to new key)
            if let oldMetadata = metadata[recording.fileName] {
                metadata.removeValue(forKey: recording.fileName)
                metadata[newFileName] = oldMetadata
                metadataStore.save(metadata)
            }

            // Update recordings array
            if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
                recordings[index] = RecordingFile(
                    fileName: newFileName,
                    fileURL: newURL,
                    duration: recording.duration,
                    dateCreated: recording.dateCreated,
                    fileSize: recording.fileSize,
                    transcript: recording.transcript
                )
            }
        } catch {
            throw AudioError.fileOperationFailed(error)
        }
    }

    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }

    // MARK: Audio level metering
    func currentLevel() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalisedLevel = pow(10, averagePower / 20)
        return max(0, min(1, normalisedLevel))
    }

    // MARK: Session/table management
    private func setupAudioSession() {
#if os(iOS)
        do {
            try audioSession.setCategory(audioSessionCategory, mode: audioSessionMode, options: audioSessionOptions)
            try audioSession.setActive(true)
            updateAvailableInputs()
        } catch {
            recordingError = .audioSessionSetupFailed(error)
        }
#endif
    }

    private func configureSessionForRecording() throws {
#if os(iOS)
        try audioSession.setCategory(audioSessionCategory, mode: audioSessionMode, options: audioSessionOptions)
        try audioSession.setActive(true)
        updateAvailableInputs()
#endif
    }

    private func loadRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )

            let audioFiles = files.filter { $0.pathExtension.lowercased() == "m4a" }
            recordings = audioFiles.compactMap { url in
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let creationDate = attributes[.creationDate] as? Date ?? Date()
                    let fileSize = attributes[.size] as? Int64 ?? 0

                    return RecordingFile(
                        fileName: url.lastPathComponent,
                        fileURL: url,
                        duration: 0,
                        dateCreated: creationDate,
                        fileSize: fileSize,
                        transcript: metadata[url.lastPathComponent]?.transcript
                    )
                } catch {
                    return nil
                }
            }.sorted { $0.dateCreated > $1.dateCreated }

            // Load durations asynchronously
            Task {
                await loadRecordingDurations()
            }
        } catch {
            recordingError = .fileOperationFailed(error)
        }
    }

    private func loadRecordingDurations() async {
        for index in recordings.indices {
            let recording = recordings[index]
            let duration = await fetchDuration(for: recording.fileURL)
            recordings[index] = RecordingFile(
                fileName: recording.fileName,
                fileURL: recording.fileURL,
                duration: duration,
                dateCreated: recording.dateCreated,
                fileSize: recording.fileSize,
                transcript: recording.transcript
            )
        }
    }

    private func fetchDuration(for url: URL) async -> TimeInterval {
        let asset = AVAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return 0
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.recordingTime += 0.1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func attachTranscript(_ transcript: String?, to recording: RecordingFile) {
        guard let index = recordings.firstIndex(where: { $0.fileName == recording.fileName }) else { return }
        let updated = recordings[index].withTranscript(transcript)
        recordings[index] = updated
        var entry = metadata[recording.fileName] ?? RecordingMetadata()
        entry.transcript = transcript
        metadata[recording.fileName] = entry
        metadataStore.save(metadata)
    }

    func equalizerSettings(for recording: RecordingFile) -> EqualizerSettings {
        metadata[recording.fileName]?.equalizerSettings ?? .flat
    }

    func updateEqualizerSettings(_ settings: EqualizerSettings, for recording: RecordingFile) {
        objectWillChange.send()
        var entry = metadata[recording.fileName] ?? RecordingMetadata()
        entry.equalizerSettings = settings
        metadata[recording.fileName] = entry
        metadataStore.save(metadata)
    }
#if os(iOS)
    private func updateAvailableInputs() {
        let inputs = audioSession.availableInputs ?? []
        isBluetoothAvailable = inputs.contains { port in
            port.portType == .bluetoothHFP || port.portType == .bluetoothA2DP || port.portType == .bluetoothLE
        }
        isExternalInputAvailable = inputs.contains { port in
            switch port.portType {
            case .headsetMic, .lineIn, .usbAudio, .carAudio:
                return true
            default:
                return false
            }
        }
    }

    private func handleRouteChange() {
        updateAvailableInputs()
        applyInputMode()
    }

    func setInputMode(_ mode: AudioInputMode) {
        inputMode = mode
        applyInputMode()
    }

    private func applyInputMode() {
        do {
            switch inputMode {
            case .builtIn:
                if let builtIn = audioSession.availableInputs?.first(where: { $0.portType == .builtInMic }) {
                    try audioSession.setPreferredInput(builtIn)
                } else {
                    try audioSession.setPreferredInput(nil)
                }
            case .external:
                if let external = audioSession.availableInputs?.first(where: { port in
                    [.headsetMic, .lineIn, .usbAudio, .carAudio].contains(port.portType)
                }) {
                    try audioSession.setPreferredInput(external)
                } else {
                    try audioSession.setPreferredInput(nil)
                }
            case .automatic:
                try audioSession.setPreferredInput(nil)
            }
        } catch {
            recordingError = .audioSessionSetupFailed(error)
        }
    }
#endif
}

// MARK: - AVAudioRecorderDelegate
@MainActor
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingError = .recordingFailed(
                NSError(
                    domain: "AudioRecorder",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Recording failed unexpectedly"]
                )
            )
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        recordingError = .recordingFailed(error ?? NSError(domain: "AudioRecorder", code: -1))
    }
}

// MARK: - Supporting types
enum PermissionStatus {
    case unknown
    case notRequested
    case granted
    case denied
}

enum AudioError: LocalizedError {
    case permissionDenied
    case audioSessionSetupFailed(Error)
    case recordingFailed(Error)
    case recordingStartFailed
    case fileOperationFailed(Error)
    case playbackFailed(Error)
    case playbackStartFailed
    case invalidFileName(String)
    case duplicateFileName(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record audio."
        case .audioSessionSetupFailed(let error):
            return "Failed to configure the audio session: \(error.localizedDescription)"
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        case .recordingStartFailed:
            return "Could not start recording. Please try again."
        case .fileOperationFailed(let error):
            return "File operation failed: \(error.localizedDescription)"
        case .playbackFailed(let error):
            return "Playback failed: \(error.localizedDescription)"
        case .playbackStartFailed:
            return "Could not start playback."
        case .invalidFileName(let reason):
            return "Invalid file name: \(reason)"
        case .duplicateFileName(let name):
            return "A recording named '\(name)' already exists."
        }
    }
}
