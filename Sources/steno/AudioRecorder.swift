import AVFoundation

class AudioRecorder: NSObject {
    private var recorder: AVAudioRecorder?
    private var outputURL: URL?

    func start() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        outputURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
    }

    func stop(completion: @escaping (URL?) -> Void) {
        recorder?.stop()
        completion(outputURL)
        outputURL = nil
    }
}
