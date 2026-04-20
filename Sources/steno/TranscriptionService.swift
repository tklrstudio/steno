import Foundation

enum TranscriptionService {
    private static let modelPath = "\(NSHomeDirectory())/.config/steno/models/ggml-base.en.bin"

    private static var whisperCLI: String? {
        ["/opt/homebrew/bin/whisper-cli", "/usr/local/bin/whisper-cli"]
            .first { FileManager.default.fileExists(atPath: $0) }
    }

    static func transcribe(_ audioURL: URL) async throws -> String {
        guard let cli = whisperCLI else { throw StenoError.whisperNotFound }
        guard FileManager.default.fileExists(atPath: modelPath) else { throw StenoError.modelNotFound }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            process.executableURL = URL(fileURLWithPath: cli)
            process.arguments = ["-m", modelPath, "-f", audioURL.path, "-nt", "-np", "-l", "en"]
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { _ in
                let raw = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if text.isEmpty {
                    continuation.resume(throwing: StenoError.emptyTranscription)
                } else {
                    continuation.resume(returning: text)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum StenoError: LocalizedError {
    case whisperNotFound
    case modelNotFound
    case emptyTranscription

    var errorDescription: String? {
        switch self {
        case .whisperNotFound: return "whisper-cli not found — run ./setup.sh"
        case .modelNotFound:   return "Whisper model not found — run ./setup.sh"
        case .emptyTranscription: return "No speech detected"
        }
    }
}
