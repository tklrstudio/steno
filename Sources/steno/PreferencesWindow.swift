import AppKit

class PreferencesWindowController: NSWindowController {
    private var keyField: NSSecureTextField!
    private var saveButton: NSButton!
    private var statusLabel: NSTextField!
    var onSave: (() -> Void)?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 160),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Steno Preferences"
        window.center()
        self.init(window: window)
        buildUI()
        loadKey()
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let label = NSTextField(labelWithString: "Groq API Key")
        label.frame = NSRect(x: 20, y: 110, width: 120, height: 20)
        content.addSubview(label)

        keyField = NSSecureTextField(frame: NSRect(x: 20, y: 80, width: 380, height: 24))
        keyField.placeholderString = "gsk_..."
        content.addSubview(keyField)

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 20, y: 54, width: 380, height: 18)
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        content.addSubview(statusLabel)

        saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.frame = NSRect(x: 320, y: 16, width: 80, height: 28)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        content.addSubview(saveButton)

        let getKeyButton = NSButton(title: "Get a free API key →", target: self, action: #selector(openGroqConsole))
        getKeyButton.frame = NSRect(x: 20, y: 20, width: 180, height: 20)
        getKeyButton.bezelStyle = .inline
        getKeyButton.isBordered = false
        getKeyButton.contentTintColor = .linkColor
        content.addSubview(getKeyButton)
    }

    private func loadKey() {
        if let key = Keychain.read("groq-api-key") {
            keyField.stringValue = key
            statusLabel.stringValue = "API key saved."
        }
    }

    @objc private func save() {
        let key = keyField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else {
            statusLabel.stringValue = "Enter your Groq API key first."
            return
        }
        Keychain.write("groq-api-key", value: key)
        statusLabel.stringValue = "Saved."
        onSave?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.close() }
    }

    @objc private func openGroqConsole() {
        NSWorkspace.shared.open(URL(string: "https://console.groq.com/keys")!)
    }
}
