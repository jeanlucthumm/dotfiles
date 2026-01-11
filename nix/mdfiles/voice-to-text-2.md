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
