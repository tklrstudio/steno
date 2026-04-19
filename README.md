# Steno

Menu bar dictation app for macOS. Hold `⌃Space`, speak, release — text is pasted wherever your cursor is.

## Setup

**1. Clone and open in Xcode**
```bash
git clone https://github.com/jasontklr/steno
cd steno
xed .
```

**2. Set your OpenAI API key**

In Xcode: Edit Scheme → Run → Arguments → Environment Variables
```
OPENAI_API_KEY = sk-...
```

**3. Grant permissions (first run)**

- **Microphone** — macOS will prompt automatically
- **Accessibility** — System Settings → Privacy & Security → Accessibility → add Steno

**4. Build and run** (`⌘R`)

The app lives in the menu bar. No Dock icon.

## Usage

| Action | Result |
|--------|--------|
| Hold `⌃Space` | Start recording (icon turns 🔴) |
| Release `⌃Space` | Transcribe and paste (icon shows ⏳ then ⬤) |
| Right-click menu bar icon | Quit |

## Requirements

- macOS 13+
- Xcode 15+
- OpenAI API key (Whisper transcription, ~$0.006/min)
