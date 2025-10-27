import Foundation

struct RecordingMetadata: Codable {
    var transcript: String?
    var equalizerSettings: EqualizerSettings?

    init(transcript: String? = nil, equalizerSettings: EqualizerSettings? = nil) {
        self.transcript = transcript
        self.equalizerSettings = equalizerSettings
    }
}

/// Persists lightweight metadata about recordings (such as transcripts) to disk.
struct RecordingMetadataStore {
    private let fileURL: URL
    private let ioQueue = DispatchQueue(label: "com.audiotext.recordingmetadata", qos: .utility)

    init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent("recordings_metadata.json")
    }

    func load() -> [String: RecordingMetadata] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: RecordingMetadata].self, from: data)
            return decoded
        } catch {
            return [:]
        }
    }

    func save(_ metadata: [String: RecordingMetadata]) {
        ioQueue.async {
            do {
                let data = try JSONEncoder().encode(metadata)
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                print("⚠️ Failed to persist recording metadata: \(error)")
            }
        }
    }
}
