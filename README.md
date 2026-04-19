# Steno

Menu bar dictation app for macOS. Hold `⌃Space`, speak, release — text is pasted wherever your cursor is.

## Setup

**1. Add your OpenAI API key**
```bash
echo "OPENAI_API_KEY=sk-..." >> ~/.config/steno/config
```

**2. Clone and open in Xcode**
```bash
git clone https://github.com/tklrstudio/steno
cd steno
xed .
```

**3. Grant Accessibility permission (one-time, manual)**

System Settings → Privacy & Security → Accessibility → add Steno

**4. Build and run** (`⌘R`)

Microphone permission is requested automatically on first use.

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
