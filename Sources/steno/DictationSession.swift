import AVFoundation
import Speech

// MARK: - Protocol

protocol DictationSession: AnyObject {
    func start() throws
    func stop() async throws -> String
}

// MARK: - Apple (chunked streaming, unlimited duration)

class AppleSession: DictationSession {
    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var mainRequest: SFSpeechAudioBufferRecognitionRequest?
    private var overlapRequest: SFSpeechAudioBufferRecognitionRequest?
    private var chunks: [(index: Int, text: String)] = []
    private var pendingCount = 0
    private var isStopping = false
    private var continuation: CheckedContinuation<String, Error>?
    private let lock = NSLock()
    private var chunkTimer: Timer?
    private var nextIndex = 0

    private static let chunkInterval: TimeInterval = 55
    private static let overlapDuration: TimeInterval = 5

    func start() throws {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            self.mainRequest?.append(buffer)
            self.overlapRequest?.append(buffer)
        }
        engine.prepare()
        try engine.start()
        beginRequest(asMain: true)
        chunkTimer = Timer.scheduledTimer(withTimeInterval: Self.chunkInterval, repeats: true) { [weak self] _ in
            self?.rotate()
        }
    }

    private func beginRequest(asMain: Bool) {
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.addsPunctuation = true
        let index = nextIndex; nextIndex += 1
        var latest = ""
        if asMain { mainRequest = req } else { overlapRequest = req }
        lock.lock(); pendingCount += 1; lock.unlock()

        recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result { latest = result.bestTranscription.formattedString }
            guard result?.isFinal == true || error != nil else { return }
            self.lock.lock()
            if !latest.isEmpty { self.chunks.append((index, latest)) }
            self.pendingCount -= 1
            let finish = self.isStopping && self.pendingCount == 0
            self.lock.unlock()
            if finish { self.finish() }
        }
    }

    private func rotate() {
        beginRequest(asMain: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.overlapDuration) { [weak self] in
            guard let self, !self.isStopping else { return }
            self.mainRequest?.endAudio()
            self.mainRequest = self.overlapRequest
            self.overlapRequest = nil
        }
    }

    func stop() async throws -> String {
        chunkTimer?.invalidate()
        chunkTimer = nil
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        return try await withCheckedThrowingContinuation { cont in
            self.lock.lock()
            self.continuation = cont
            self.isStopping = true
            let alreadyDone = self.pendingCount == 0
            self.lock.unlock()
            if alreadyDone { self.finish() } else {
                self.mainRequest?.endAudio()
                self.overlapRequest?.endAudio()
            }
        }
    }

    private func finish() {
        guard let cont = continuation else { return }
        continuation = nil
        let sorted = chunks.sorted { $0.index < $1.index }.map { $0.text }
        let text = sorted.reduce("", Self.join).trimmingCharacters(in: .whitespaces)
        text.isEmpty ? cont.resume(throwing: StenoError.emptyTranscription)
                     : cont.resume(returning: text)
    }

    // Overlap deduplication: find longest suffix of `a` that matches a prefix of `b`
    static func join(_ a: String, _ b: String) -> String {
        guard !a.isEmpty else { return b }
        guard !b.isEmpty else { return a }
        let aWords = a.split(separator: " ").map(String.init)
        let bWords = b.split(separator: " ").map(String.init)
        let maxK = min(30, aWords.count, bWords.count)
        for k in stride(from: maxK, through: 1, by: -1) {
            let aTail = aWords.suffix(k).map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            let bHead = Array(bWords.prefix(k)).map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            if aTail == bHead {
                let remainder = bWords.dropFirst(k).joined(separator: " ")
                return remainder.isEmpty ? a : a + " " + remainder
            }
        }
        return a + " " + b
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

// MARK: - Groq (cloud Whisper)

class GroqSession: DictationSession {
    private var recorder: AVAudioRecorder?
    private var audioURL: URL?

    static var apiKey: String? { Keychain.read("groq-api-key") ?? Config["GROQ_API_KEY"] }

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
        try? await Task.sleep(nanoseconds: 400_000_000) // capture tail of last word
        recorder?.stop()
        guard let url = audioURL else { throw StenoError.emptyTranscription }
        guard let key = GroqSession.apiKey else { throw StenoError.groqKeyMissing }

        let boundary = UUID().uuidString
        var body = Data()
        let audioData = try Data(contentsOf: url)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-large-v3-turbo\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONDecoder().decode(GroqTranscriptionResponse.self, from: data)
        let text = json.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw StenoError.emptyTranscription }
        return text
    }
}

private struct GroqTranscriptionResponse: Decodable {
    let text: String
}

// MARK: - Errors

enum StenoError: LocalizedError {
    case whisperNotFound, modelNotFound, emptyTranscription
    case speechPermissionDenied, speechUnavailable
    case groqKeyMissing

    var errorDescription: String? {
        switch self {
        case .whisperNotFound:        return "whisper-cli not found — run ./setup.sh"
        case .modelNotFound:          return "Whisper model not found — run ./setup.sh"
        case .emptyTranscription:     return "No speech detected"
        case .speechPermissionDenied: return "Speech recognition permission denied"
        case .speechUnavailable:      return "Speech recognizer unavailable"
        case .groqKeyMissing:         return "Groq API key not set — add GROQ_API_KEY to ~/.config/steno/config"
        }
    }
}
