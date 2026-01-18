# Voice-to-text dictation using Whisper
# Two modes:
#   1. Push-to-talk (Cmd+Shift+P): Hold to record, release to transcribe
#   2. VAD mode (Cmd+Shift+O): Toggle continuous listening with voice activity detection
{
  pkgs,
  config,
  ...
}: let
  # Available models (speed vs accuracy tradeoff):
  #   tiny, tiny.en, base, base.en, small, medium, large-v3, large-v3-turbo
  model = "base.en";
  silenceMs = 1500; # VAD: silence duration before transcription

  # Push-to-talk daemon - keeps whisper model loaded, accepts audio file paths via socket
  whisperDaemon = pkgs.writers.writePython3Bin "whisper-daemon" {
    libraries = with pkgs.python3Packages; [faster-whisper];
    flakeIgnore = ["E501"];
  } ''
    """Whisper transcription daemon."""
    from faster_whisper import WhisperModel
    import socket
    import os
    import signal
    import sys

    SOCKET_PATH = "/tmp/whisper.sock"
    MODEL = "${model}"


    def main():
        print(f"Loading model '{MODEL}'...")
        model = WhisperModel(MODEL, device="auto")
        print("Model loaded")

        if os.path.exists(SOCKET_PATH):
            os.remove(SOCKET_PATH)

        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(SOCKET_PATH)
        server.listen(1)

        def cleanup(sig, frame):
            print("\nShutting down...")
            server.close()
            if os.path.exists(SOCKET_PATH):
                os.remove(SOCKET_PATH)
            sys.exit(0)

        signal.signal(signal.SIGINT, cleanup)
        signal.signal(signal.SIGTERM, cleanup)

        print(f"Whisper daemon ready on {SOCKET_PATH}")
        while True:
            conn, _ = server.accept()
            try:
                audio_path = conn.recv(1024).decode().strip()
                segments, _ = model.transcribe(audio_path, language="en")
                text = " ".join(s.text for s in segments).strip()
                conn.send(text.encode())
            except Exception as e:
                print(f"Error: {e}")
                conn.send(b"")
            finally:
                conn.close()


    if __name__ == "__main__":
        main()
  '';

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
                subprocess.run(["pbcopy"], input=text.encode(), check=True)
                subprocess.run([
                    "osascript", "-e",
                    'tell application "System Events" to keystroke "v" using command down'
                ], check=True)
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
in {
  programs.hammerspoon.extraConfig = ''
    -- Push-to-talk dictation with Whisper
    -- Hold Cmd+Shift+P to record, release to transcribe and paste
    local dictLog = hs.logger.new("dictation", "info")
    local dictPid = nil
    local dictFile = "/tmp/dictation.wav"
    local ffmpeg = "${pkgs.ffmpeg}/bin/ffmpeg"

    local function startRecording()
        dictLog.i("Starting recording")
        local task = hs.task.new(ffmpeg, nil, {
            "-f", "avfoundation", "-i", ":default", "-y", dictFile
        })
        task:start()
        dictPid = task:pid()
    end

    local function stopAndTranscribe()
        if dictPid then
            os.execute("kill -INT " .. dictPid)
            dictPid = nil

            hs.timer.doAfter(0.1, function()
                local text, status = hs.execute("echo '" .. dictFile .. "' | nc -U /tmp/whisper.sock")
                if status and text and text ~= "" then
                    text = text:gsub("^%s*(.-)%s*$", "%1")
                    hs.pasteboard.setContents(text)
                    hs.eventtap.keyStroke({"cmd"}, "v")
                else
                    dictLog.e("Transcription failed or empty")
                end
            end)
        end
    end

    hs.hotkey.bind({"cmd", "shift"}, "p", startRecording, stopAndTranscribe)
    dictLog.i("Dictation hotkey registered (Cmd+Shift+P)")

    -- VAD mode: Toggle continuous listening
    -- Press Cmd+Shift+O to start/stop
    local vadTask = nil
    local vadBin = "${vadDictation}/bin/vad-dictation"

    local function toggleVAD()
        if vadTask and vadTask:isRunning() then
            dictLog.i("Stopping VAD mode")
            vadTask:terminate()
            vadTask = nil
            hs.alert.show("🎤 VAD Off")
        else
            dictLog.i("Starting VAD mode")
            vadTask = hs.task.new(vadBin, function(exitCode, stdOut, stdErr)
                dictLog.i("VAD task exited with code " .. tostring(exitCode))
                vadTask = nil
            end)
            vadTask:start()
            hs.alert.show("🎤 VAD On")
        end
    end

    hs.hotkey.bind({"cmd", "shift"}, "o", toggleVAD)
    dictLog.i("VAD toggle hotkey registered (Cmd+Shift+O)")
  '';

  launchd.agents.whisper-daemon = {
    enable = true;
    config = {
      Label = "com.jeanluc.whisper-daemon";
      Program = "${whisperDaemon}/bin/whisper-daemon";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/whisper-daemon.log";
      StandardErrorPath = "/tmp/whisper-daemon.err";
    };
  };
}
