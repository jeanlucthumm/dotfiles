# Project: Voice-to-Keyboard Input for macOS Development

## Overview

A local, privacy-preserving voice input system that transcribes speech in real-time and types it directly into any application. Designed for hands-free coding with AI agents like Claude Code, but useful for any text input scenario.

## Problem

When working with coding agents, you're constantly typing natural language instructions. Voice input would be faster and reduce fatigue, but:

- macOS built-in dictation requires internet and has mediocre accuracy
- Commercial solutions have privacy concerns and subscription costs
- Existing tools don't integrate cleanly with a Nix-based dev environment

## Solution

A lightweight pipeline combining:

1. **faster-whisper** (via whisper-ctranslate2) for high-accuracy local transcription
1. **cliclick** for injecting transcribed text as keyboard input
1. A simple daemon/script with hotkey activation

```
microphone → whisper-ctranslate2 → stdout → cliclick → active window
```

## Why These Tools

| Component | Rationale |
|-----------|-----------|
| whisper-ctranslate2 | CLI wrapper around faster-whisper, outputs to stdout, supports live transcription, active maintenance |
| faster-whisper | 4x faster than OpenAI Whisper, lower memory usage, good Apple Silicon performance via CPU |
| cliclick | Lightweight macOS-native, single binary, no dependencies, fast keystroke injection |

## Nix Considerations

- **ctranslate2 / faster-whisper** — Already in nixpkgs
- **whisper-ctranslate2** — Python package, can add via poetry2nix or pip in a venv
- **cliclick** — Not in nixpkgs; either package it (simple single-file Obj-C project) or use Homebrew as escape hatch

## Status: Implemented

### What was built

Push-to-talk voice dictation for macOS:

- **Hotkey**: Cmd+Shift+P (hold to record, release to transcribe)
- **Recording**: ffmpeg with avfoundation, records to `/tmp/dictation.wav`
- **Transcription**: faster-whisper daemon keeps model in memory for fast inference
- **Output**: Copies to clipboard and pastes via Cmd+V

### Architecture changes from proposal

| Proposed | Implemented | Reason |
|----------|-------------|--------|
| cliclick for typing | pbcopy + Cmd+V paste | Faster than character-by-character typing |
| whisper-ctranslate2 CLI | faster-whisper Python daemon | Avoid model reload latency on each transcription |
| Live streaming | Push-to-talk with batch transcribe | Cleaner UX, avoids partial transcriptions |

### Files

- `home/modules/darwin/dictation.nix` — Whisper daemon + launchd service
- `~/.hammerspoon/init.lua` — Hotkey binding (ffmpeg recording + socket client)

### Model selection

Using `base.en` for speed. Edit `model` variable in `dictation.nix` to change:
- `tiny.en` / `base.en` — fastest
- `small` / `medium` — balanced
- `large-v3-turbo` — most accurate
