import Foundation

enum Config {
    static subscript(key: String) -> String? {
        if let val = ProcessInfo.processInfo.environment[key], !val.isEmpty { return val }
        return fromFile[key]
    }

    private static let fromFile: [String: String] = {
        let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".config/steno/config")
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        return contents.split(separator: "\n").reduce(into: [:]) { dict, line in
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 { dict[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces) }
        }
    }()
}
