import AppKit
import AVFoundation
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey!
    private let recorder = AudioRecorder()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupHotKey()
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

    private func startRecording() {
        setIcon("🔴")
        recorder.start()
    }

    private func stopAndTranscribe() {
        setIcon("⏳")
        recorder.stop { [weak self] audioURL in
            guard let audioURL else { self?.setIcon("⬤"); return }
            Task {
                do {
                    let text = try await TranscriptionService.transcribe(audioURL)
                    Injector.paste(text + " ")
                    self?.setIcon("⬤")
                } catch {
                    print("Steno error: \(error)")
                    self?.setIcon("❌")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.setIcon("⬤")
                    }
                }
            }
        }
    }

    private func setIcon(_ icon: String) {
        DispatchQueue.main.async {
            self.statusItem.button?.title = icon
        }
    }
}
