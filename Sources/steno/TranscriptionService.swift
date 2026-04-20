import Foundation

enum TranscriptionService {
    static func transcribe(_ audioURL: URL) async throws -> String {
        let backend = Config["STENO_BACKEND"] ?? "apple"
        switch backend {
        case "whisper": return try await WhisperBackend.transcribe(audioURL)
        default:        return try await AppleSpeechBackend.transcribe(audioURL)
        }
    }
}

// MARK: - Apple Speech (default)

import Speech

private enum AppleSpeechBackend {
    static func transcribe(_ audioURL: URL) async throws -> String {
        if SFSpeechRecognizer.authorizationStatus() != .authorized {
            let granted = await requestPermission()
            guard granted else { throw StenoError.speechPermissionDenied }
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            throw StenoError.speechUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error { continuation.resume(throwing: error); return }
                if let result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    private static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

// MARK: - Whisper.cpp

private enum WhisperBackend {
    private static let modelsDir = "\(NSHomeDirectory())/.config/steno/models"

    private static var modelPath: String {
        let name = Config["STENO_MODEL"] ?? "ggml-base.en"
        return "\(modelsDir)/\(name).bin"
    }

    private static var threads: String {
        Config["STENO_THREADS"] ?? "\(max(1, ProcessInfo.processInfo.processorCount - 2))"
    }

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
            process.arguments = ["-m", modelPath, "-f", audioURL.path, "-nt", "-np", "-l", "en", "-t", threads]
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

            do { try process.run() } catch { continuation.resume(throwing: error) }
        }
    }
}

// MARK: - Errors

enum StenoError: LocalizedError {
    case whisperNotFound
    case modelNotFound
    case emptyTranscription
    case speechPermissionDenied
    case speechUnavailable

    var errorDescription: String? {
        switch self {
        case .whisperNotFound:       return "whisper-cli not found — run ./setup.sh"
        case .modelNotFound:        return "Whisper model not found — run ./setup.sh"
        case .emptyTranscription:   return "No speech detected"
        case .speechPermissionDenied: return "Speech recognition permission denied"
        case .speechUnavailable:    return "Speech recognizer unavailable"
        }
    }
}
