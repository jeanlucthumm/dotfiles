# Voice-to-text dictation using Whisper
{
  pkgs,
  config,
  ...
}: let
  # Available models (speed vs accuracy tradeoff):
  #   tiny, tiny.en, base, base.en, small, medium, large-v3, large-v3-turbo
  model = "base.en";

  python = pkgs.python313.withPackages (ps: [ps.faster-whisper]);

  whisperDaemon = pkgs.writeScript "whisper-daemon" ''
    #!${python}/bin/python3
    """
    Whisper transcription daemon - keeps model loaded in memory for fast transcription.
    Listens on a Unix socket for audio file paths and returns transcribed text.
    """
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
in {
  home.packages = with pkgs; [
    whisper-ctranslate2
    python313Packages.sounddevice
  ];

  launchd.agents.whisper-daemon = {
    enable = true;
    config = {
      Label = "com.jeanluc.whisper-daemon";
      Program = "${whisperDaemon}";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/whisper-daemon.log";
      StandardErrorPath = "/tmp/whisper-daemon.err";
    };
  };
}
