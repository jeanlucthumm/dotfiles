# Voice-to-text dictation using Whisper (NixOS/Wayland version)
# VAD mode (Mod+Shift+O): Toggle continuous listening with voice activity detection
{pkgs, ...}: let
  # Available models (speed vs accuracy tradeoff):
  #   tiny, tiny.en, base, base.en, small, medium, large-v3, large-v3-turbo
  model = "base.en";
  silenceMs = 1500; # VAD: silence duration before transcription

  # VAD mode - continuous listening with voice activity detection
  vadDictation = pkgs.writers.writePython3Bin "vad-dictation" {
    libraries = with pkgs.python3Packages; [
      faster-whisper
      sounddevice
      pysilero-vad
      numpy
    ];
    flakeIgnore = ["E501"];
  } ''
    """VAD dictation - continuous listening with voice activity detection."""
    import subprocess
    import sys
    import tempfile
    import threading
    import time
    import wave
    from enum import Enum

    import numpy as np
    import sounddevice as sd
    from faster_whisper import WhisperModel
    from pysilero_vad import SileroVoiceActivityDetector

    MODEL = "${model}"
    SILENCE_MS = ${toString silenceMs}
    SAMPLE_RATE = 16000
    CHANNELS = 1
    CHUNK_SAMPLES = 512
    SPEECH_THRESHOLD = 0.5


    class State(Enum):
        IDLE = "idle"
        RECORDING = "recording"
        PAUSED = "paused"


    class VADDictation:
        def __init__(self):
            self.state = State.IDLE
            self.audio_buffer: list[np.ndarray] = []
            self.silence_chunks = 0
            self.lock = threading.Lock()

            chunk_duration_ms = (CHUNK_SAMPLES / SAMPLE_RATE) * 1000
            self.silence_threshold_chunks = int(SILENCE_MS / chunk_duration_ms)

            print("Loading VAD model...")
            self.vad = SileroVoiceActivityDetector()

            print(f"Loading Whisper model '{MODEL}'...")
            self.model = WhisperModel(MODEL, device="auto")

            print(f"Ready! Silence threshold: {SILENCE_MS}ms ({self.silence_threshold_chunks} chunks)")
            print("Listening... (Ctrl+C to stop)")

        def audio_callback(self, indata: np.ndarray, frames: int, time_info, status):
            if status:
                print(f"Audio status: {status}", file=sys.stderr)

            audio_float = indata[:, 0].astype(np.float32)

            try:
                prob = self.vad.process_samples(audio_float)
            except Exception as e:
                print(f"VAD error: {e}", file=sys.stderr)
                return

            is_speech = prob > SPEECH_THRESHOLD

            with self.lock:
                if self.state == State.IDLE:
                    if is_speech:
                        print("▶ Speech detected, recording...")
                        self.state = State.RECORDING
                        self.audio_buffer = [indata.copy()]
                        self.silence_chunks = 0

                elif self.state == State.RECORDING:
                    self.audio_buffer.append(indata.copy())
                    if not is_speech:
                        self.state = State.PAUSED
                        self.silence_chunks = 1

                elif self.state == State.PAUSED:
                    self.audio_buffer.append(indata.copy())
                    if is_speech:
                        self.state = State.RECORDING
                        self.silence_chunks = 0
                    else:
                        self.silence_chunks += 1
                        if self.silence_chunks >= self.silence_threshold_chunks:
                            buffer_copy = self.audio_buffer.copy()
                            self.audio_buffer = []
                            self.state = State.IDLE
                            threading.Thread(
                                target=self.transcribe_and_paste,
                                args=(buffer_copy,),
                                daemon=True
                            ).start()

        def transcribe_and_paste(self, audio_chunks: list[np.ndarray]):
            print("⏸ Transcribing...")
            audio = np.concatenate(audio_chunks)

            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                temp_path = f.name
                with wave.open(f, "wb") as wav:
                    wav.setnchannels(CHANNELS)
                    wav.setsampwidth(2)
                    wav.setframerate(SAMPLE_RATE)
                    audio_int16 = (audio[:, 0] * 32767).astype(np.int16)
                    wav.writeframes(audio_int16.tobytes())

            try:
                segments, _ = self.model.transcribe(temp_path, language="en")
                text = " ".join(s.text for s in segments).strip()
            except Exception as e:
                print(f"Transcription error: {e}", file=sys.stderr)
                return

            if text:
                print(f'✓ "{text}"')
                subprocess.run(["${pkgs.wl-clipboard}/bin/wl-copy"], input=(text + " ").encode(), check=True)
                subprocess.run(["${pkgs.wtype}/bin/wtype", "-M", "ctrl", "v", "-m", "ctrl"], check=True)
            else:
                print("✗ (empty transcription)")

        def run(self):
            with sd.InputStream(
                samplerate=SAMPLE_RATE,
                channels=CHANNELS,
                dtype=np.float32,
                blocksize=CHUNK_SAMPLES,
                callback=self.audio_callback,
            ):
                while True:
                    time.sleep(0.1)


    if __name__ == "__main__":
        dictation = VADDictation()
        try:
            dictation.run()
        except KeyboardInterrupt:
            print("\nStopped.")
  '';

  # Toggle script with notification feedback
  toggleVad = pkgs.writeShellScriptBin "toggle-vad" ''
    if ${pkgs.procps}/bin/pgrep -f "vad-dictation" > /dev/null; then
      ${pkgs.procps}/bin/pkill -f "vad-dictation"
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation" "VAD Off"
    else
      ${vadDictation}/bin/vad-dictation &
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation" "VAD On"
    fi
  '';
in {
  home.packages = [
    pkgs.wtype # For simulating keypresses in Wayland
    toggleVad
    vadDictation
  ];

  # Niri keybind for VAD toggle
  programs.niri.settings.binds."Mod+Shift+O".action.spawn = ["toggle-vad"];
}
