# Local AI Instructions — Steno

**Purpose:** Workspace-specific context for Steno
**Status:** Canonical
**Scope:** This workspace only
**Created:** 2026-04-20
**Last Updated:** 2026-04-20
**Version:** 1.0.0

This is an open-source repo — the `.living-systems/` submodule is not included. Use this file and `_context/CHARTER.md` as primary context.

---

## Scope

Personal productivity tool — macOS menu bar dictation. Swift, open source, personal use.

**Workspace code:** `STN`
**Decision prefix:** `DEC-STN`

---

## Architecture

- `Sources/steno/AppDelegate.swift` — menu bar, hotkey, orchestration
- `Sources/steno/DictationSession.swift` — `DictationSession` protocol + `AppleSession` (streaming SFSpeechRecognizer) + `WhisperSession` (whisper-cli subprocess)
- `Sources/steno/Injector.swift` — clipboard write + CGEventPost Cmd+V
- `Sources/steno/Config.swift` — reads env vars then `~/.config/steno/config`
- `Support/` — Info.plist, LaunchAgent plist, signing cert
- `build.sh` — compile, sign, install to `~/Applications`, relaunch
- `setup.sh` — install whisper-cpp via Homebrew + download model
- `setup-signing.sh` — create persistent self-signed code signing cert

## Config (`~/.config/steno/config`)

| Key | Default | Values |
|-----|---------|--------|
| `STENO_BACKEND` | `apple` | `apple`, `whisper` |
| `STENO_MODEL` | `ggml-base.en` | any ggml model name in `~/.config/steno/models/` |
| `STENO_THREADS` | `processorCount - 2` | integer |

---

## Context Files

1. `_context/CHARTER.md` — Project definition, boundaries, success criteria
2. `temporal/WORK_IN_PROGRESS.md` — What is currently in flight

---

**End Local AI Instructions — Steno**
