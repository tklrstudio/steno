# Decision: Create Steno — macOS Menu Bar Dictation App

**Purpose:** Document the decision to build Steno, a hotkey-triggered voice dictation tool for macOS
**Status:** Canonical

<!-- Filename: DEC-STN-2026-04-20-150000_create-steno-dictation-app.md -->

**Created:** 2026-04-20
**Decision Status:** Implemented
**Decision ID:** DEC-STN-2026-04-20-150000
**Workspace:** steno
**Branch:** Operations

---

## Problem

Typing is slow. Speaking is 3–4× faster and lower friction for composing messages, notes, and code comments. Existing tools (Wispr Flow et al.) solve this well but cost money and require trusting a third party with audio. A personal tool built to the exact workflow needed — and running entirely on-device — is better on every axis.

**Background:**
Observed Wispr Flow in use and recognised the pattern: system-wide voice injection is a solved problem technically. The core loop is short: record mic → transcribe → paste. The only hard part is OS-level text injection, which on macOS is handled by `CGEventPost` + clipboard.

**Current state:**
No dictation tool in use. All text input via keyboard.

---

## Constitutional Alignment

- [x] **Values** — Autonomy (Tier 1): own your tools, own your data. Systems Thinking (Tier 1): a well-designed capture tool reduces friction across every other system.
- [x] **Temporal** — Supports career transition velocity — faster writing means more output across JEC, MSM, and operational work.
- [ ] **Contexts** — N/A
- [ ] **Foundations** — N/A
- [x] **Modes** — Operator: personal tooling to reduce daily friction.
- [x] **Algorithms** — Avoids over-engineering: built in one session, shipped as a personal tool, no premature abstraction.

---

## Decision

Build a macOS menu bar app that records audio on hotkey hold, transcribes on release, and pastes the result into whatever app has focus. Ship it as open source under the TKLR Studio GitHub org.

**Rationale:**
- Scope is small and well-defined — one session to MVP
- On-device transcription (Apple SFSpeechRecognizer) is fast, free, and private
- Clipboard injection via `CGEventPost` works universally across all apps
- No cloud dependency, no subscription, no data leaving the machine

**Alternatives considered:**
1. **Wispr Flow (commercial)**: Rejected — costs money, audio leaves device, not customisable
2. **macOS built-in dictation**: Rejected — not hotkey-triggered, not programmable, pastes inconsistently
3. **OpenAI Whisper API**: Evaluated as primary backend, replaced by on-device Apple Speech for speed and zero cost. Retained as optional `whisper` backend.

**Scope:**
- macOS only, personal use
- Swift Package, no App Store
- Two backends: `apple` (default, streaming, on-device) and `whisper` (local whisper.cpp)
- Hotkey: `⌥Space` (hold to record, release to paste)

---

## Consequences

### Positive
- Typing friction eliminated for message composition, notes, and long-form writing
- Zero ongoing cost — fully on-device
- Audio never leaves the machine
- Customisable — backends, models, hotkey all configurable

### Neutral
- Requires one-time Accessibility permission grant in System Settings
- Persistent code signing cert required to prevent TCC permission resets on rebuild

### Risks
- Apple Speech accuracy degrades with heavy accent or domain-specific vocabulary — `whisper` backend available as fallback

---

## Execution Checklist

### 1. Actions
- [x] Swift Package scaffolded with HotKey dependency
- [x] `AppDelegate` — menu bar item, `⌥Space` hotkey, icon state machine (⬤ → 🔴 → ⏳ → ⬤)
- [x] `DictationSession` protocol — pluggable backends
- [x] `AppleSession` — streaming `AVAudioEngine` + `SFSpeechAudioBufferRecognitionRequest`, on-device, `addsPunctuation = true`
- [x] `WhisperSession` — `AVAudioRecorder` to WAV + `whisper-cli` subprocess
- [x] `Injector` — clipboard write + `CGEventPost` Cmd+V with clipboard restore
- [x] `Config` — env var + `~/.config/steno/config` file reader
- [x] `build.sh` — compile, sign, install to `~/Applications`, relaunch
- [x] `setup.sh` — Homebrew whisper-cpp install + model download
- [x] `setup-signing.sh` — persistent self-signed cert to survive TCC across rebuilds
- [x] `LaunchAgent` — auto-start on login
- [x] Trailing space appended after each transcription
- [x] Repo scaffolded with living-systems structure

### 2. Documentation
- [x] `README.md` — setup and usage
- [x] `_context/CHARTER.md`
- [x] `LOCAL_AI_INSTRUCTIONS.md`
- [x] This decision document
- [x] Project registry entry in `living-systems`

### 3. AI Usage Guide Required
- No AI guide required — personal tool, no team usage

### 4. Human Usage Guide Required
- No human guide required — README covers it

### 5. Change Explainer Required
- No explainer required — new standalone tool, no existing users affected

### 6. Cross-References and Subsystem Impact
- Registry entry added to `living-systems/temporal/PROJECT_REGISTRY.md`
- No other repos affected

### 7. Verification
- [x] `⌥Space` triggers recording, releases paste transcribed text
- [x] Works in Claude desktop, Chrome, Edge, Teams, Terminal
- [x] Accessibility permission survives rebuild (persistent signing cert)
- [x] App auto-starts on login via LaunchAgent
- [x] Trailing space pasted after each transcription

---

## Problems Solved

| # | Problem | Impact | Resolution |
|---|---------|--------|------------|
| 1 | `⌃Space` conflicts with macOS input source switching | Hotkey non-functional | Changed to `⌥Space` |
| 2 | Ad-hoc signing resets TCC Accessibility permission on every rebuild | Permission lost after each build | Created persistent self-signed cert via `setup-signing.sh` |
| 3 | `com.apple.security.device.audio-input` entitlement caused repeated mic prompts | Mic permission prompt on every launch | Removed entitlement (sandbox-only, not needed for non-sandboxed apps) |
| 4 | Apple Speech backend slow (6s) because transcription started after recording stopped | Unusable latency | Switched to streaming `SFSpeechAudioBufferRecognitionRequest` — recognition runs in parallel with recording |
| 5 | `build.sh` didn't kill running instance before relaunching | Old binary kept running after rebuild | Added `pkill -x steno` before `open` |

---

## Execution Record

**Executed:** 2026-04-20
**Executed by:** Jason + Claude Sonnet 4.6 (Claude Code)
**Result:** Success

**Notes:**
Built end-to-end in one session. Initial backend was OpenAI Whisper API, replaced with local whisper.cpp for zero cost, then superseded by Apple's streaming SFSpeechRecognizer for sub-second latency. The signing cert setup was the most fiddly part — OpenSSL 3/macOS keychain compatibility required legacy PKCS12 algorithms.

**Artefacts:**
- `Sources/steno/` — all Swift source files
- `build.sh`, `setup.sh`, `setup-signing.sh`
- `Support/Info.plist`, `Support/net.tklr.steno.plist`, `Support/signing/cert.pem`
- `Package.swift`, `Package.resolved`
- `_context/CHARTER.md`, `LOCAL_AI_INSTRUCTIONS.md`
- Registry entry in `living-systems`

**Verification results:**
App tested live during the build session. Latency with Apple streaming backend confirmed fast. Pasting confirmed working in Claude desktop, Chrome, Teams.

**Lessons learned:**
- Start with the native platform SDK (SFSpeechRecognizer) before reaching for external APIs — it's often fast enough and has zero cost
- Ad-hoc code signing and TCC don't mix — establish a signing cert at repo creation, not as a fix
- `build.sh` should always kill the running process before relaunching

---

## Related

**Goals:**
- Reduce daily typing friction (primary)

**Commitments:**
- N/A — personal tooling

**Decisions:**
- N/A — standalone new tool

---

**End of Decision Record**
