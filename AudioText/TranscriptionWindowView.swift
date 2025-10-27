import SwiftUI

struct TranscriptionWindowView: View {
    let transcription: String

    var body: some View {
        NavigationView {
            ScrollView {
                Text(transcription.isEmpty ? "No transcription available yet." : transcription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Transcription")
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}
