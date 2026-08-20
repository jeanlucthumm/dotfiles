# skhd — fn+letter hotkeys for the most used apps (Darwin only).
# fn+i/o/p are safe: macOS reserves other Globe combos (fn+E, fn+Q, ...).
{jlib, ...}: {
  flake.modules.homeManager.graphical = jlib.mkHomeManager {
    darwin = {
      services.skhd = {
        enable = true;
        config = ''
          fn - i : open -a "Slack"
          fn - o : open -a "kitty"
          fn - p : open -a "Google Chrome"
        '';
      };
    };
  };
}
