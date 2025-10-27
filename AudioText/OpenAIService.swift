import SwiftUI
import Foundation

/// Async wrapper around the OpenAI Whisper transcription endpoint with safety checks.
@MainActor
class OpenAIService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionText = ""
    @Published var transcriptionError: OpenAIError?
    @Published var apiKeyValid = false

    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    private var apiKey: String = ""
    private let maxFileSize: Int64 = 25 * 1024 * 1024 // 25 MB
    private let supportedFormats = ["mp3", "mp4", "mpeg", "mpga", "m4a", "wav", "webm"]
    private let urlSession: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        urlSession = URLSession(configuration: configuration)
    }

    func setAPIKey(_ key: String) {
        apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKeyValid = apiKey.hasPrefix("sk-") && apiKey.count > 20
    }

    func transcribeAudio(
        from url: URL,
        language: String = "auto",
        textStyle: String = "Any changes",
        model: String = "whisper-1"
    ) async throws -> String {
        guard apiKeyValid else {
            throw OpenAIError.missingAPIKey
        }

        guard isFileSupported(url) else {
            throw OpenAIError.unsupportedFileFormat
        }

        guard isFileSizeValid(url) else {
            throw OpenAIError.fileTooLarge
        }

        isTranscribing = true
        transcriptionText = ""
        transcriptionError = nil
        defer { isTranscribing = false }

        do {
            let result = try await performTranscription(url: url, language: language, textStyle: textStyle, model: model)
            transcriptionText = result
            return result
        } catch let error as OpenAIError {
            transcriptionError = error
            throw error
        } catch {
            let wrapped = OpenAIError.networkError(error)
            transcriptionError = wrapped
            throw wrapped
        }
    }

    private func performTranscription(
        url: URL,
        language: String,
        textStyle: String,
        model: String
    ) async throws -> String {
        let boundary = UUID().uuidString
        var body = Data()

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField(name: "model", value: model)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.\(url.pathExtension)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/\(url.pathExtension)\r\n\r\n".data(using: .utf8)!)

        do {
            let audioData = try Data(contentsOf: url)
            body.append(audioData)
        } catch {
            throw OpenAIError.fileReadFailed(error)
        }

        if language != "auto" {
            appendField(name: "language", value: language)
        }

        let prompt = generatePrompt(for: textStyle)
        if !prompt.isEmpty {
            appendField(name: "prompt", value: prompt)
        }

        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = body

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let transcriptionResponse = try JSONDecoder().decode(OpenAITranscriptionResponse.self, from: data)
            return transcriptionResponse.text
        case 401:
            throw OpenAIError.invalidAPIKey
        case 429:
            throw OpenAIError.rateLimitExceeded
        case 400...499:
            throw OpenAIError.clientError(httpResponse.statusCode)
        case 500...599:
            throw OpenAIError.serverError(httpResponse.statusCode)
        default:
            throw OpenAIError.unknownError(httpResponse.statusCode)
        }
    }

    private func isFileSupported(_ url: URL) -> Bool {
        supportedFormats.contains(url.pathExtension.lowercased())
    }

    private func isFileSizeValid(_ url: URL) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            return fileSize <= maxFileSize
        } catch {
            return false
        }
    }

    private func generatePrompt(for textStyle: String) -> String {
        switch textStyle {
        case "Improve clarity":
            return "Please transcribe this audio with improved clarity and proper punctuation."
        case "Academic":
            return "Please transcribe this audio in an academic style with formal language and proper structure."
        case "Podcast":
            return "Please transcribe this audio as if it were a podcast transcript with natural speech patterns."
        case "Semi casual":
            return "Please transcribe this audio in a semi-casual style, maintaining some informality while remaining clear."
        case "Casual":
            return "Please transcribe this audio in a casual, conversational style."
        default:
            return ""
        }
    }
}

struct OpenAITranscriptionResponse: Codable {
    let text: String
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case rateLimitExceeded
    case clientError(Int)
    case serverError(Int)
    case unknownError(Int)
    case networkError(Error)
    case invalidResponse
    case transcriptionFailed(Error)
    case fileReadFailed(Error)
    case unsupportedFileFormat
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is required."
        case .invalidAPIKey:
            return "The provided API key is invalid."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .clientError(let code):
            return "Client error with status code \(code)."
        case .serverError(let code):
            return "Server error with status code \(code)."
        case .unknownError(let code):
            return "Unknown error (\(code))."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from OpenAI."
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .fileReadFailed(let error):
            return "Failed to read audio file: \(error.localizedDescription)"
        case .unsupportedFileFormat:
            return "Unsupported audio file format."
        case .fileTooLarge:
            return "Audio file is too large (max 25 MB)."
        }
    }
}
