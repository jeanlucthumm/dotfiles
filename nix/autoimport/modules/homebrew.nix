# Homebrew on every Darwin host. nix-homebrew installs brew itself (and adopts a
# hand-installed /opt/homebrew); nix-darwin's `homebrew` module then runs
# `brew bundle` on activation. Cleanup stays off, so anything installed by hand
# survives. Hosts add casks/brews via `homebrew.casks` / `homebrew.brews`.
fp: {
  flake.modules.darwin.base = {config, ...}: {
    imports = [fp.inputs.nix-homebrew.darwinModules.nix-homebrew];

    nix-homebrew = {
      enable = true;
      user = config.system.primaryUser;
      autoMigrate = true;
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "none";
      };
    };
  };
}
