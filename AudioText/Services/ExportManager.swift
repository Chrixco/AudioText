import Foundation
import CoreGraphics
import CoreText

#if os(iOS)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformWeight = UIFont.Weight
typealias PlatformColor = UIColor
#else
import AppKit
typealias PlatformFont = NSFont
typealias PlatformWeight = NSFont.Weight
typealias PlatformColor = NSColor
#endif

enum ExportManager {
    enum Format: String, CaseIterable {
        case pdf
        case word

        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .word: return "rtf"
            }
        }

        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .word: return "Word (RTF)"
            }
        }
    }

    enum ExportError: LocalizedError {
        case pdfGenerationFailed

        var errorDescription: String? {
            "Failed to generate PDF export."
        }
    }

    static func export(
        recording: RecordingFile,
        transcript: String,
        format: Format
    ) throws -> URL {
        let attributed = makeAttributedTranscript(for: recording, transcript: transcript)

        let data: Data
        switch format {
        case .pdf:
            data = try makePDFData(from: attributed)
        case .word:
            data = try makeRTFData(from: attributed)
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let sanitizedName = sanitizedFileName(from: recording.fileName, fallback: "Recording")
        let fileName = "\(sanitizedName)-Transcript.\(format.fileExtension)"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    private static func makeRTFData(from attributed: NSAttributedString) throws -> Data {
        try attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    private static func makePDFData(from attributed: NSAttributedString) throws -> Data {
        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData as CFMutableData) else {
            throw ExportError.pdfGenerationFailed
        }

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ExportError.pdfGenerationFailed
        }

        context.beginPDFPage(nil)

        let insetRect = mediaBox.insetBy(dx: 40, dy: 40)
        let path = CGMutablePath()
        path.addRect(insetRect)

        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attributed.length), path, nil)
        CTFrameDraw(frame, context)

        context.endPDFPage()
        context.closePDF()

        return mutableData as Data
    }

    private static func sanitizedFileName(from name: String, fallback: String) -> String {
        let base = name.split(separator: ".").first.map(String.init) ?? fallback
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>")
        return base.components(separatedBy: invalid).joined(separator: "_")
    }

    private static func makeAttributedTranscript(for recording: RecordingFile, transcript: String) -> NSMutableAttributedString {
        let headlineAttributes: [NSAttributedString.Key: Any] = [
            .font: font(size: 20, weight: .semibold)
        ]
        let metaAttributes: [NSAttributedString.Key: Any] = [
            .font: font(size: 13, weight: .regular),
            .foregroundColor: colorGray
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: font(size: 15, weight: .regular)
        ]

        let content = NSMutableAttributedString(
            string: "\(cleanName(from: recording.fileName))\n",
            attributes: headlineAttributes
        )

        let duration = recording.formattedDuration
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: recording.dateCreated)

        let metadata = "Created: \(dateString)\nDuration: \(duration)\n\n"
        content.append(NSAttributedString(string: metadata, attributes: metaAttributes))

        content.append(NSAttributedString(string: transcript, attributes: bodyAttributes))

        return content
    }

    private static func cleanName(from fileName: String) -> String {
        if let dot = fileName.lastIndex(of: ".") {
            return String(fileName[..<dot])
        }
        return fileName
    }

    private static func font(size: CGFloat, weight: PlatformWeight) -> PlatformFont {
        PlatformFont.systemFont(ofSize: size, weight: weight)
    }

    private static var colorGray: PlatformColor {
#if os(iOS)
        return PlatformColor.secondaryLabel
#else
        return PlatformColor.secondaryLabelColor
#endif
    }
}
