import AVFoundation
import Speech

// MARK: - Protocol

protocol DictationSession: AnyObject {
    func start() throws
    func stop() async throws -> String
}

// MARK: - Apple (streaming)

class AppleSession: DictationSession {
    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var continuation: CheckedContinuation<String, Error>?

    func start() throws {
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = false
        request?.addsPunctuation = true

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        engine.prepare()
        try engine.start()

        task = recognizer.recognitionTask(with: request!) { [weak self] result, error in
            guard let self, let cont = self.continuation else { return }
            if let error {
                cont.resume(throwing: error)
                self.continuation = nil
            } else if let result, result.isFinal {
                cont.resume(returning: result.bestTranscription.formattedString)
                self.continuation = nil
            }
        }
    }

    func stop() async throws -> String {
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            request?.endAudio()
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
    }
}

// MARK: - Whisper (file-based)

class WhisperSession: DictationSession {
    private var recorder: AVAudioRecorder?
    private var audioURL: URL?

    private static var modelPath: String {
        let name = Config["STENO_MODEL"] ?? "ggml-base.en"
        return "\(NSHomeDirectory())/.config/steno/models/\(name).bin"
    }

    private static var threads: String {
        Config["STENO_THREADS"] ?? "\(max(1, ProcessInfo.processInfo.processorCount - 2))"
    }

    private static var whisperCLI: String? {
        ["/opt/homebrew/bin/whisper-cli", "/usr/local/bin/whisper-cli"]
            .first { FileManager.default.fileExists(atPath: $0) }
    }

    func start() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        audioURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
    }

    func stop() async throws -> String {
        recorder?.stop()
        guard let url = audioURL else { throw StenoError.emptyTranscription }

        guard let cli = WhisperSession.whisperCLI else { throw StenoError.whisperNotFound }
        guard FileManager.default.fileExists(atPath: WhisperSession.modelPath) else { throw StenoError.modelNotFound }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()

            process.executableURL = URL(fileURLWithPath: cli)
            process.arguments = ["-m", WhisperSession.modelPath, "-f", url.path, "-nt", "-np", "-l", "en", "-t", WhisperSession.threads]
            process.standardOutput = stdout
            process.standardError = Pipe()

            process.terminationHandler = { _ in
                let raw = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                text.isEmpty
                    ? continuation.resume(throwing: StenoError.emptyTranscription)
                    : continuation.resume(returning: text)
            }

            do { try process.run() } catch { continuation.resume(throwing: error) }
        }
    }
}

// MARK: - Errors

enum StenoError: LocalizedError {
    case whisperNotFound, modelNotFound, emptyTranscription
    case speechPermissionDenied, speechUnavailable

    var errorDescription: String? {
        switch self {
        case .whisperNotFound:        return "whisper-cli not found — run ./setup.sh"
        case .modelNotFound:          return "Whisper model not found — run ./setup.sh"
        case .emptyTranscription:     return "No speech detected"
        case .speechPermissionDenied: return "Speech recognition permission denied"
        case .speechUnavailable:      return "Speech recognizer unavailable"
        }
    }
}
