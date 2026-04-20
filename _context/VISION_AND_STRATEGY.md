# Steno Vision and Strategy

**Created:** 2026-04-20
**Last Updated:** 2026-04-20

---

## What Steno Is For

Steno exists for one reason: typing is slow and I want to stop doing it.

Speaking is 3–4× faster than typing for composing messages, notes, documents, and code comments. The goal is to be able to reach for my voice instead of my keyboard whenever I'm writing — in any app, without switching context, without friction, without cost.

This is a personal productivity tool. It is not a product, not a platform, not a business. It lives quietly in the menu bar and gets out of the way.

---

## Design Principles

**1. Zero ongoing cost**
Transcription runs on-device using Apple's built-in speech recognition. No API subscriptions, no usage fees. The moment a per-use cost is introduced, the tool becomes something I think about instead of something I use.

**2. No latency that breaks flow**
The reason to use voice is speed. If transcription takes longer than typing, the tool has failed its own purpose. Target: result pasted before the thought is gone. Sub-second after releasing the hotkey.

**3. No complexity, no configuration rabbit holes**
Steno should require no attention after initial setup. One hotkey. One menu bar icon. No dashboards, no settings screens, no tuning loops. If I'm thinking about Steno, something is wrong.

**4. Works everywhere I work**
Chrome, Edge, Teams, Claude desktop, Terminal. No per-app setup. The clipboard injection approach means it works in any text field on macOS without needing to know which app is focused.

**5. Private by default**
Audio never leaves the machine. On-device Apple Speech is the default and preferred backend. The whisper.cpp backend is available for those who want Whisper-quality transcription without any cloud dependency.

---

## What Steno Is Not

- Not a product for others (it's open source but built for personal use)
- Not a transcription service (it doesn't save audio or produce transcripts)
- Not a voice assistant (it types what you say, nothing more)
- Not a replacement for a keyboard (it complements it)

---

## Backends

| Backend | Cost | Latency | Quality | When to use |
|---------|------|---------|---------|-------------|
| `apple` (default) | Free | Sub-second | Good | Daily use |
| `whisper` | Free | 2–7s (Intel) | Excellent | When accuracy matters more than speed |

The `apple` backend is the daily driver. `whisper` is available for cases where accuracy on technical vocabulary or accents matters more than response time.

---

## Scope Boundary

Steno does one thing: hold hotkey → speak → paste. Any feature that adds complexity, cost, or latency to that loop is out of scope unless it clearly makes the core loop better. No transcription history, no cloud sync, no team features, no AI post-processing by default.

---

**End of Vision and Strategy**
