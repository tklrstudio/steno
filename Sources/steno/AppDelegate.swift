import AppKit
import Speech
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey!
    private var activeSession: DictationSession?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupHotKey()
        requestPermissions()
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        // Mic permission is requested by AVAudioEngine on first use
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "⬤"
        statusItem.button?.toolTip = "Steno — hold ⌥Space to dictate"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Steno", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setupHotKey() {
        hotKey = HotKey(key: .space, modifiers: [.option])
        hotKey.keyDownHandler = { [weak self] in self?.startRecording() }
        hotKey.keyUpHandler = { [weak self] in self?.stopAndTranscribe() }
    }

    private func makeSession() -> DictationSession {
        let backend = Config["STENO_BACKEND"]
        if backend == "whisper" { return WhisperSession() }
        if backend == "groq"    { return GroqSession() }
        return AppleSession()
    }

    private func startRecording() {
        let session = makeSession()
        activeSession = session
        do {
            try session.start()
            setIcon("🔴")
        } catch {
            activeSession = nil
            setIcon("❌")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.setIcon("⬤") }
        }
    }

    private func stopAndTranscribe() {
        guard let session = activeSession else { setIcon("⬤"); return }
        activeSession = nil
        setIcon("⏳")

        Task {
            do {
                let text = try await session.stop()
                Injector.paste(text + " ")
                setIcon("⬤")
            } catch {
                setIcon("❌")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.setIcon("⬤") }
            }
        }
    }

    private func setIcon(_ icon: String) {
        DispatchQueue.main.async { self.statusItem.button?.title = icon }
    }
}
