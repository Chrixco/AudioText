import XCTest
@testable import AudioText

final class AudioTextTests: XCTestCase {
    
    func test_TranscriptionResult_Initialization_Success() throws {
        // Given
        let text = "Hello, world!"
        let duration: TimeInterval = 2.5
        
        // When
        let result = TranscriptionResult(text: text, duration: duration)
        
        // Then
        XCTAssertEqual(result.text, text)
        XCTAssertEqual(result.duration, duration)
        XCTAssertNotNil(result.timestamp)
    }
    
    func test_AudioFile_Initialization_Success() throws {
        // Given
        let data = Data("test audio data".utf8)
        let format = AudioFormat.m4a
        let duration: TimeInterval = 3.0
        
        // When
        let audioFile = AudioFile(data: data, format: format, duration: duration)
        
        // Then
        XCTAssertEqual(audioFile.data, data)
        XCTAssertEqual(audioFile.format, format)
        XCTAssertEqual(audioFile.duration, duration)
        XCTAssertNotNil(audioFile.createdAt)
    }
    
    func test_AudioFormat_MimeType_ReturnsCorrectValue() throws {
        // Given & When & Then
        XCTAssertEqual(AudioFormat.m4a.mimeType, "audio/m4a")
        XCTAssertEqual(AudioFormat.wav.mimeType, "audio/wav")
        XCTAssertEqual(AudioFormat.mp3.mimeType, "audio/mp3")
    }
    
    func test_WhisperError_LocalizedDescription_ReturnsCorrectMessage() throws {
        // Given & When & Then
        XCTAssertEqual(WhisperError.apiKeyNotConfigured.errorDescription, 
                      "OpenAI API key is not configured. Please set OPENAI_API_KEY environment variable.")
        XCTAssertEqual(WhisperError.invalidResponse.errorDescription, 
                      "Invalid response from OpenAI API")
        
        let apiError = WhisperError.apiError(statusCode: 401, message: "Unauthorized")
        XCTAssertTrue(apiError.errorDescription?.contains("401") == true)
        XCTAssertTrue(apiError.errorDescription?.contains("Unauthorized") == true)
    }
    
    func test_AudioRecorderError_LocalizedDescription_ReturnsCorrectMessage() throws {
        // Given & When & Then
        XCTAssertEqual(AudioRecorderError.audioEngineNotAvailable.errorDescription, 
                      "Audio engine is not available")
        XCTAssertEqual(AudioRecorderError.microphonePermissionDenied.errorDescription, 
                      "Microphone permission is required to record audio")
    }
}
