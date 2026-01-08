# Voice Dictation Post-Processor for Coding Agents

## Problem

When dictating natural language prompts to coding agents (Claude, Cursor, etc.), speech-to-text engines misrecognize codebase-specific terms like class names, function names, and technical jargon. Commercial tools solve this with custom vocabularies, but OSS options (Whisper) lack this feature.

## Solution

A lightweight post-processor that takes Whisper transcription output and uses an LLM to correct domain-specific terms against a known wordlist extracted from the codebase.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Whisper   │────▶│   Post-     │────▶│  Corrected  │────▶│  Clipboard/ │
│  (local)    │     │  Processor  │     │    Text     │     │   Stdout    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Wordlist   │
                    │  (symbols   │
                    │  from code) │
                    └─────────────┘
```

## Components

### 1. Symbol Extractor (`extract_symbols.py`)

Parses codebase to extract vocabulary terms. For a Dart/Flutter project:

**Extract:**

- Class names
- Function/method names (public)
- Enum names and values
- Top-level constants
- File names (without extension)
- Common library names (Terra, Oura, Whoop, etc.)

**Output:** `wordlist.txt` - one term per line

**Implementation options:**

- Tree-sitter for Dart parsing (accurate)
- Regex-based extraction (simpler, good enough)
- LSP query if available

**Run:** On-demand or as pre-commit hook to keep wordlist fresh.

### 2. Post-Processor (`correct_transcript.py`)

Takes raw transcript + wordlist, returns corrected transcript.

**Input:**

- `transcript: str` - raw Whisper output
- `wordlist: list[str]` - domain terms

**LLM Prompt:**

```
You are a transcript corrector for a software developer. 
Fix any misrecognized technical terms in this transcript.

Known terms from the codebase:
{wordlist}

Transcript:
{transcript}

Return ONLY the corrected transcript, no explanation.
```

**LLM Options (in order of preference for local/cheap):**

1. Claude API (claude-3-5-haiku) - fast, cheap, accurate
1. Local llama.cpp with small model (Qwen2.5-3B, Phi-3)
1. Ollama with mistral/llama3

### 3. CLI Wrapper (`dictate.py`)

Main entry point. Options:

```bash
# Basic usage - record, transcribe, correct, copy to clipboard
dictate

# Specify wordlist
dictate --wordlist ./cora/wordlist.txt

# Output to stdout instead of clipboard
dictate --stdout

# Skip correction (raw Whisper output)
dictate --raw

# Regenerate wordlist from codebase
dictate --extract ./cora/lib
```

### 4. System Integration

**Option A: Hotkey daemon**

- Background process listening for hotkey (e.g., F5)
- Press to start recording, press again to stop
- Result goes to clipboard, paste anywhere

**Option B: CLI-only**

- Run from terminal
- Records until silence detected or Enter pressed
- Result to stdout or clipboard

## Dependencies

```
whisper.cpp or faster-whisper  # Local Whisper
pyaudio or sounddevice         # Audio capture
anthropic or ollama            # LLM client
pyperclip                      # Clipboard (optional)
tree-sitter-dart               # Symbol extraction (optional)
```

## File Structure

```
voice-dictate/
├── dictate.py              # CLI entry point
├── extract_symbols.py      # Codebase parser
├── correct_transcript.py   # LLM post-processor
├── transcribe.py           # Whisper wrapper
├── wordlist.txt            # Generated vocabulary
├── config.yaml             # Settings (paths, LLM choice, hotkey)
└── requirements.txt
```

## Config (`config.yaml`)

```yaml
whisper:
  model: "base.en"  # tiny.en, base.en, small.en, medium.en
  
llm:
  provider: "anthropic"  # or "ollama", "openai"
  model: "claude-3-5-haiku-20241022"
  
codebase:
  paths:
    - "./lib"
  extensions:
    - ".dart"
  extra_terms:
    - "Terra API"
    - "Oura"
    - "Whoop"
    - "Ultrahuman"
    - "HealthKit"

output:
  clipboard: true
  notify: true  # macOS notification on completion
```

## MVP Scope

1. **Phase 1:** CLI that takes audio file → corrected transcript
1. **Phase 2:** Live recording with silence detection
1. **Phase 3:** Hotkey daemon for system-wide access
1. **Phase 4:** Wordlist auto-refresh on file changes

## Open Questions

1. **Silence detection threshold** - how long before auto-stop?
1. **Wordlist size limits** - if codebase has 1000+ symbols, truncate or chunk?
1. **Latency budget** - acceptable delay between speech end and output?
1. **Fuzzy matching** - should LLM also catch near-misses not in wordlist?

## Success Criteria

- End-to-end latency < 3 seconds for typical prompt (10-30 words)
- Correctly recognizes 90%+ of codebase terms after correction
- Works offline (with local Whisper + Ollama fallback)

## References

- [OpenAI Cookbook: Whisper post-processing](https://cookbook.openai.com/examples/whisper_correct_misspelling)
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper)
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp)
