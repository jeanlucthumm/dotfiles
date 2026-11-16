# skhd — fn+letter hotkeys for the most used apps (Darwin only).
# fn+i/o/p are safe: macOS reserves other Globe combos (fn+E, fn+Q, ...).
{jlib, ...}: {
  flake.modules.homeManager.graphical = jlib.mkHomeManager {
    darwin = {pkgs, ...}: {
      services.skhd = {
        # TODO: disabled: the Accessibility grant was lost on every upgrade.
        # signStable alone is not enough, macOS also tracks the store path.
        # Before re-enabling, route the package through jl.stableExe as well
        # (see stable-exe.nix).
        enable = false;
        package = pkgs.signStable pkgs.skhd;
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
