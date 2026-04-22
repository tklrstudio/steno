---
name: Deployments
description: Machine-specific deployment notes for Steno
type: reference
status: Canonical
scope: Project
created: 2026-04-22
last_updated: 2026-04-22
---

# Steno Deployments

Two machines run Steno. They share the same codebase but differ in build toolchain, backend, and config.

---

## Mac Mini (primary)

**Backend:** Apple on-device speech (default — no Groq key configured)
**Build toolchain:** System `swift` via Xcode
**Config:** `~/.config/steno/config` — none required for default behaviour

**Notes:**
- Established setup, no deviations from Charter
- On-device only, zero latency overhead, fully private

---

## MacBook Air (secondary)

**Backend:** Groq (`whisper-large-v3-turbo`) when online — falls back to Apple when offline
**Build toolchain:** Swift 6.1.2 from swift.org (required — CLT 16.4 has a broken `PackageDescription` dylib that prevents SPM from resolving the manifest with any `swift-tools-version`)

**Setup steps (one-time):**
1. Download and install toolchain: `https://download.swift.org/swift-6.1.2-release/xcode/swift-6.1.2-RELEASE/swift-6.1.2-RELEASE-osx.pkg`
2. Create signing cert: `./setup-signing.sh` (patched — requires `-legacy` flag for openssl pkcs12 export due to macOS keychain compatibility)
3. Set env var in `~/.zprofile`: `export SWIFT_TOOLCHAIN=/Library/Developer/Toolchains/swift-6.1.2-RELEASE.xctoolchain/usr/bin/swift`
4. Add Groq API key to `~/.config/steno/config`: `GROQ_API_KEY=gsk_...`
5. Run `./build.sh`
6. Grant Accessibility + Microphone permissions in System Settings

**Config** (`~/.config/steno/config`):
```
GROQ_API_KEY=gsk_...
```

**Charter deviation:** Groq is a cloud transcription service, which the Charter lists as out of scope. This is intentional for the MacBook Air — the built-in mic picks up more background noise than the Mac Mini's setup, and Groq's `whisper-large-v3-turbo` is more robust in those conditions. Revisit if privacy or offline requirements change.

**Known differences from Mac Mini:**
- 400ms tail delay added to Groq session (`DictationSession.swift`) to prevent last-word cutoff on key release
- Groq adds ~1–2s cloud round-trip latency vs near-instant Apple backend
- Falls back to Apple session automatically when offline

---

## Rebuilding

Both machines use `./build.sh`. The script reads `SWIFT_TOOLCHAIN` from the environment:
- Mac Mini: unset → uses system `swift`
- MacBook Air: set in `~/.zprofile` → uses swift.org toolchain

Accessibility and Microphone TCC permissions survive rebuilds (app bundle is updated in-place via `rsync`, not deleted and recreated).
