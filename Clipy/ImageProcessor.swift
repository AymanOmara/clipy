//
//  ImageProcessor.swift
//  Clipy
//
//  Created by Ayman Omara on 25/09/2026.
//

import AppKit
import CryptoKit
import Vision

/// CPU-heavy image work (hashing, PNG encoding, text recognition), kept off the main thread.
nonisolated enum ImageProcessor {
    struct ProcessedImage: Sendable {
        let pngData: Data
        let hash: String
        let pixelSize: CGSize
    }

    /// Hash of the raw pasteboard bytes; identical copies produce identical hashes.
    static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func encodePNG(tiffData: Data) -> (png: Data, size: CGSize)? {
        guard let bitmap = NSBitmapImageRep(data: tiffData),
              let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
        return (png, CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh))
    }

    /// Recognises text in an image with the Vision framework; nil when nothing readable is found.
    static func recognizeText(in imageData: Data) -> String? {
        guard let bitmap = NSBitmapImageRep(data: imageData), let cgImage = bitmap.cgImage else { return nil }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("[ImageProcessor] Text recognition failed: \(error)")
            return nil
        }
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
