import Foundation

/// Shared model representing a locally stored audio recording.
/// Centralising this struct avoids divergence between iOS and macOS targets.
struct RecordingFile: Identifiable, Codable, Equatable {
    let id: UUID
    let fileName: String
    let fileURL: URL
    let duration: TimeInterval
    let dateCreated: Date
    let fileSize: Int64
    let transcript: String?

    init(
        id: UUID = UUID(),
        fileName: String,
        fileURL: URL,
        duration: TimeInterval,
        dateCreated: Date,
        fileSize: Int64 = 0,
        transcript: String? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.duration = duration
        self.dateCreated = dateCreated
        self.fileSize = fileSize
        self.transcript = transcript
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateCreated)
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    func withTranscript(_ transcript: String?) -> RecordingFile {
        RecordingFile(
            id: id,
            fileName: fileName,
            fileURL: fileURL,
            duration: duration,
            dateCreated: dateCreated,
            fileSize: fileSize,
            transcript: transcript
        )
    }
}
