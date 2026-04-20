# Steno Charter

**Purpose:** Stop typing. Speak instead — in any app, for free, without delays.
**Status:** Canonical
**Scope:** Project
**Branch:** Operations
**Workspace Code:** STN
**Type:** Software
**Created:** 2026-04-20
**Last Updated:** 2026-04-20
**Version:** 1.0.0

---

## Purpose

Steno eliminates typing friction. Hold `⌥Space`, speak, release — transcribed text is pasted wherever the cursor is. It runs on-device, costs nothing, and stays out of the way.

See `VISION_AND_STRATEGY.md` for the full design philosophy.

## Success Criteria

- Transcription result pasted before the thought is gone (sub-second with Apple backend)
- Works in any macOS app with a text field — no per-app configuration
- Zero ongoing cost — fully on-device by default
- Runs silently in the menu bar, starts on login, requires no attention

## Boundaries

**In scope:**
- macOS menu bar app, hotkey-triggered dictation
- On-device Apple Speech backend (default) and local whisper.cpp backend
- Clipboard injection via CGEventPost — universal, no app-specific code

**Out of scope:**
- iOS, Windows, or any non-macOS platform
- Cloud transcription services (cost and latency)
- Transcription history, dashboards, or settings UI
- Team features or multi-user support
- AI post-processing (adds latency, adds cost)

---

**End of Charter**
