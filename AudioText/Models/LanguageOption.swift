import Foundation

struct LanguageOption: Identifiable, Equatable {
    let label: String
    let code: String

    var id: String { code }
}

extension LanguageOption {
    static let baseOptions: [LanguageOption] = [
        .init(label: "English", code: "en-US"),
        .init(label: "Spanish", code: "es-ES"),
        .init(label: "Portuguese", code: "pt-PT"),
        .init(label: "German", code: "de-DE"),
        .init(label: "French", code: "fr-FR")
    ]

    static func options(for method: TranscriptionMethod) -> [LanguageOption] {
        let autoLabel = method == .openAI ? "Auto (Detect)" : "System Language"
        return [.init(label: autoLabel, code: "auto")] + baseOptions
    }

    static func label(for code: String, method: TranscriptionMethod) -> String {
        let options = options(for: method)
        return options.first(where: { $0.code == code })?.label
            ?? (method == .openAI ? "Auto (Detect)" : "System Language")
    }
}
