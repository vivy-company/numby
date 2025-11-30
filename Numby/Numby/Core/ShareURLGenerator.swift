//
//  ShareURLGenerator.swift
//  Numby
//
//  Generates share URLs for web-based sharing
//

import Foundation
import Compression

struct ShareURLGenerator {

    /// Generate a share URL for the given calculation lines and theme
    static func generate(lines: [(expression: String, result: String)], theme: String) -> URL {
        let payload: [String: Any] = [
            "v": 1,
            "l": lines.map { [$0.expression, $0.result] },
            "t": theme
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            // Fallback to simple URL if encoding fails
            return URL(string: "https://numby.vivy.app")!
        }

        let compressed = compress(jsonData)
        let base64 = compressed.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))

        return URL(string: "https://numby.vivy.app/s#\(base64)")!
    }

    /// Compress data using zlib
    private static func compress(_ data: Data) -> Data {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count * 2)
        defer { destinationBuffer.deallocate() }

        let compressedSize = data.withUnsafeBytes { sourceBuffer -> Int in
            guard let sourcePointer = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return 0
            }
            return compression_encode_buffer(
                destinationBuffer,
                data.count * 2,
                sourcePointer,
                data.count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard compressedSize > 0 else {
            return data // Return uncompressed if compression fails
        }

        return Data(bytes: destinationBuffer, count: compressedSize)
    }

    /// Generate plain text representation for sharing
    static func generateText(lines: [(expression: String, result: String)]) -> String {
        lines.map { "\($0.expression) → \($0.result)" }.joined(separator: "\n")
    }
}
