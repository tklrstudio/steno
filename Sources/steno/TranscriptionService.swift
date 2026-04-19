import Foundation

enum TranscriptionService {
    static func transcribe(_ audioURL: URL) async throws -> String {
        guard let apiKey = Config["OPENAI_API_KEY"] else {
            throw StenoError.missingAPIKey("OPENAI_API_KEY")
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try buildBody(audioURL: audioURL, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw StenoError.apiError(String(data: data, encoding: .utf8) ?? "unknown")
        }

        return try JSONDecoder().decode(WhisperResponse.self, from: data).text
    }

    private static func buildBody(audioURL: URL, boundary: String) throws -> Data {
        var body = Data()
        let audioData = try Data(contentsOf: audioURL)

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1\r\n")
        body.append("--\(boundary)--\r\n")

        return body
    }
}

private struct WhisperResponse: Decodable {
    let text: String
}

enum StenoError: LocalizedError {
    case missingAPIKey(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let key): return "Missing env var: \(key)"
        case .apiError(let msg): return "API error: \(msg)"
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}
