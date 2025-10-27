import Foundation

struct TranscriptionResult: Codable, Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
    let duration: TimeInterval?
    
    init(text: String, duration: TimeInterval? = nil) {
        self.text = text
        self.timestamp = Date()
        self.duration = duration
    }
}

struct AudioFile: Codable, Identifiable {
    let id = UUID()
    let data: Data
    let format: AudioFormat
    let duration: TimeInterval
    let createdAt: Date
    
    init(data: Data, format: AudioFormat, duration: TimeInterval) {
        self.data = data
        self.format = format
        self.duration = duration
        self.createdAt = Date()
    }
}

enum AudioFormat: String, CaseIterable, Codable {
    case m4a = "m4a"
    case wav = "wav"
    case mp3 = "mp3"
    
    var mimeType: String {
        switch self {
        case .m4a:
            return "audio/m4a"
        case .wav:
            return "audio/wav"
        case .mp3:
            return "audio/mp3"
        }
    }
}
