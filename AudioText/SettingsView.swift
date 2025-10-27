import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var audioRecorder: AudioRecorder
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    @EnvironmentObject private var openAIService: OpenAIService

    @Binding var transcriptionMethod: TranscriptionMethod
    @Binding var selectedLanguageCode: String
    @Binding var selectedTextStyle: String
    @Binding var apiKey: String

    private let textStyles = [
        "Any changes",
        "Improve clarity",
        "Academic",
        "Podcast",
        "Semi casual",
        "Casual"
    ]

    private var languageOptions: [LanguageOption] {
        LanguageOption.options(for: transcriptionMethod)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Permissions") {
                    SettingStatusRow(title: "Microphone", status: microphoneStatus)
                    SettingStatusRow(title: "Speech Recognition", status: speechStatus)

                    Button("Request Permissions") {
                        Task {
                            await audioRecorder.requestPermissions()
                            await speechRecognizer.requestPermissions()
                            refreshStatuses()
                        }
                    }
                    .disabled(microphoneStatus == .granted && speechStatus == .granted)
                }

                Section("Transcription Method") {
                    Picker("Method", selection: $transcriptionMethod) {
                        ForEach(TranscriptionMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    if transcriptionMethod == .builtIn {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("✅ Built-in Dictation")
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text("Uses Apple's Speech Recognition. No API key required.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        // On-device toggle
                        if speechRecognizer.supportsOnDeviceRecognition {
                            Toggle("Use On-Device Recognition", isOn: $speechRecognizer.useOnDeviceRecognition)
                                .tint(.blue)

                            VStack(alignment: .leading, spacing: 6) {
                                if speechRecognizer.useOnDeviceRecognition {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("On-Device Mode")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            Text("✓ Unlimited recording duration\n✓ Works offline\n✓ Private (stays on device)\n⚠️ Slightly less accurate")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                } else {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "network")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Server-Based Mode")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            Text("✓ Better accuracy\n⚠️ Requires internet\n⚠️ Max 1 minute per recording\n⚠️ 1,000 requests/hour limit")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text("On-device recognition not available on this device. Using server-based mode with 1-minute limit.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    if transcriptionMethod == .openAI {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "cloud.fill")
                                    .foregroundStyle(.purple)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("OpenAI Whisper Limits")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("✓ Very accurate\n✓ Multiple languages\n✓ Max ~27 minutes (25 MB file limit)\n⚠️ Requires internet\n⚠️ Costs $0.006/minute")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                if transcriptionMethod == .openAI {
                    Section("API Configuration") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OpenAI API Key")
                                .font(.headline)
                            SecureField("Enter your API key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
#if os(iOS)
                                .textInputAutocapitalization(.never)
#endif
                                .onChange(of: apiKey) { _, newValue in
                                    openAIService.setAPIKey(newValue)
                                }
                            Text("Required for Whisper transcription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Language Settings") {
                    Picker("Language", selection: $selectedLanguageCode) {
                        ForEach(languageOptions) { option in
                            Text(option.label).tag(option.code)
                        }
                    }
                    .pickerStyle(.menu)

                    if transcriptionMethod == .builtIn {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ℹ️ Language Note")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("Built-in dictation follows your selected language. Choose the language you plan to speak during recording.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ℹ️ Language Note")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("OpenAI can detect the spoken language automatically when Auto is selected.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }

                if transcriptionMethod == .openAI {
                    Section("Text Style") {
                        Picker("Text Style", selection: $selectedTextStyle) {
                            ForEach(textStyles, id: \.self) { style in
                                Text(style).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AudioText")
                            .font(.headline)
                        Text("AI-powered audio transcription for iPhone, iPad, and Mac.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
#else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
#endif
        }
        .onAppear(perform: refreshStatuses)
    }

    private func refreshStatuses() {
        audioRecorder.refreshPermissions()
        speechRecognizer.refreshPermissions()
    }

    private var microphoneStatus: PermissionBadge {
        switch audioRecorder.permissionStatus {
        case .granted: return .granted
        case .denied: return .denied
        case .notRequested: return .unknown
        case .unknown: return .unknown
        }
    }

    private var speechStatus: PermissionBadge {
        switch speechRecognizer.permissionStatus {
        case .granted: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notRequested: return .unknown
        case .unknown: return .unknown
        }
    }
}

private struct SettingStatusRow: View {
    let title: String
    let status: PermissionBadge

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status.label)
                .foregroundStyle(status.color)
        }
    }
}

private enum PermissionBadge: Equatable {
    case granted
    case denied
    case restricted
    case unknown

    var label: String {
        switch self {
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .granted: return .green
        case .denied: return .red
        case .restricted: return .orange
        case .unknown: return .secondary
        }
    }
}

enum TranscriptionMethod: String, CaseIterable, Identifiable {
    case builtIn
    case openAI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .builtIn: return "Built-in Dictation"
        case .openAI: return "OpenAI Whisper"
        }
    }
}
