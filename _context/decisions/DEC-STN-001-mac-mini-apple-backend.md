---
id: DEC-STN-001
title: Mac Mini uses Apple on-device backend permanently
status: Accepted
date: 2026-04-24
---

# DEC-STN-001 — Mac Mini uses Apple on-device backend permanently

## Context

Mac Mini was silently configured with `STENO_BACKEND=groq` in `~/.config/steno/config`, contrary to what DEPLOYMENTS.md described. When the Groq API key expired (returning 403), Steno started failing on every dictation attempt with no useful error visible to the user (just ❌ in the menu bar).

The failure mode was opaque: recording appeared to start (🔴), the hourglass appeared (⏳), then ❌. There was no log, no notification, and no fallback.

## Decision

Mac Mini runs Apple on-device speech recognition exclusively. `STENO_BACKEND` is not set in the config — the default Apple path is taken. No Groq key is configured.

## Rationale

- **Offline:** Apple backend works without network. Groq requires api.groq.com to be reachable and the key to be valid — two external dependencies that can silently break.
- **Private:** Audio never leaves the device. Groq sends audio to a cloud API.
- **Latency:** Apple backend is near-instant. Groq adds ~1–2s round-trip.
- **Cost:** Apple is free. Groq is currently free-tier but that can change.
- **Charter alignment:** The Charter explicitly lists cloud transcription as out of scope. Groq on Mac Mini was an undocumented deviation with no recorded justification.

## Consequences

- Mac Mini dictation is faster and works offline.
- If Apple's speech recognizer is unavailable (e.g., permission revoked, macOS issue), there is no automatic fallback — the failure will be visible as ❌.
- The MacBook Air continues to use Groq as its primary backend (documented deviation — noisier mic environment justifies it).

## What Changed

- Removed `STENO_BACKEND=groq`, `GROQ_API_KEY`, and `STENO_MODEL` from `~/.config/steno/config` on Mac Mini.
- Updated `_context/DEPLOYMENTS.md` to accurately reflect Mac Mini config.
