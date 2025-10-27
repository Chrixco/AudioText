import XCTest

final class AudioTextUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func test_AppLaunch_DisplaysMainInterface() throws {
        // Given & When
        // App is launched in setUp
        
        // Then
        XCTAssertTrue(app.staticTexts["AudioText"].exists)
        XCTAssertTrue(app.buttons.matching(identifier: "recordingButton").firstMatch.exists)
    }
    
    func test_RecordingButton_Tap_StartsRecording() throws {
        // Given
        let recordingButton = app.buttons.matching(identifier: "recordingButton").firstMatch
        
        // When
        recordingButton.tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["Recording..."].exists)
    }
    
    func test_RecordingButton_WhileRecording_StopsRecording() throws {
        // Given
        let recordingButton = app.buttons.matching(identifier: "recordingButton").firstMatch
        recordingButton.tap() // Start recording
        
        // When
        recordingButton.tap() // Stop recording
        
        // Then
        XCTAssertFalse(app.staticTexts["Recording..."].exists)
    }
    
    func test_TranscriptionDisplay_ShowsResult() throws {
        // Given
        let recordingButton = app.buttons.matching(identifier: "recordingButton").firstMatch
        
        // When
        recordingButton.tap()
        // Simulate transcription result
        // Note: In a real test, you would mock the WhisperService
        
        // Then
        // Verify transcription UI elements exist
        XCTAssertTrue(app.staticTexts["Transcription:"].exists)
    }
    
    func test_CopyButton_Exists() throws {
        // Given
        // App with transcription result displayed
        
        // When
        // Simulate having a transcription result
        
        // Then
        XCTAssertTrue(app.buttons.matching(identifier: "copyButton").firstMatch.exists)
    }
    
    func test_ShareButton_Exists() throws {
        // Given
        // App with transcription result displayed
        
        // When
        // Simulate having a transcription result
        
        // Then
        XCTAssertTrue(app.buttons.matching(identifier: "shareButton").firstMatch.exists)
    }
    
    func test_ClearButton_Exists() throws {
        // Given
        // App with transcription result displayed
        
        // When
        // Simulate having a transcription result
        
        // Then
        XCTAssertTrue(app.buttons.matching(identifier: "clearButton").firstMatch.exists)
    }
}
