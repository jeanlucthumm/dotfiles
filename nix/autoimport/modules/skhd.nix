# skhd — fn+letter hotkeys for the most used apps (Darwin only).
# fn+i/o/p are safe: macOS reserves other Globe combos (fn+E, fn+Q, ...).
{jlib, ...}: {
  flake.modules.homeManager.graphical = jlib.mkHomeManager {
    darwin = {
      services.skhd = {
        enable = true;
        # Absolute path: skhd execs through $SHELL (nushell here), whose
        # `open` builtin shadows the macOS launcher and has no -a flag.
        config = ''
          fn - i : /usr/bin/open -a "Slack"
          fn - o : /usr/bin/open -a "kitty"
          fn - p : /usr/bin/open -a "Google Chrome"
        '';
      };
    };
  };
}
