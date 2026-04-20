# Steno Charter

**Purpose:** macOS menu bar dictation app — speak anywhere, paste instantly
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

Steno eliminates typing friction for anyone who speaks faster than they type. Hold a hotkey, speak, release — transcribed text is pasted into whatever app has focus.

## Success Criteria

- Transcription latency under 1 second for typical utterances
- Works in any macOS app with a text field (Chrome, Edge, Teams, Claude, Terminal)
- Zero ongoing cost (on-device recognition by default)
- Runs silently in the menu bar, starts on login

## Boundaries

- **In scope:** macOS menu bar app, hotkey-triggered dictation, on-device Apple Speech backend, local whisper.cpp backend, clipboard injection
- **Out of scope:** iOS/Windows, cloud transcription services, multi-user, audio editing

---

**End of Charter**
