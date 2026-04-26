# CLI
{
  flake.modules.nixos.cli = {pkgs, ...}: {
    # Basic sytem wide packages
    environment.systemPackages = with pkgs; [
      file # Figure out what a certain file is
      lsof # Open files (but good for ports)
      tmux # Terminal multiplexer
      git # Version control
      nushell # Shell so I don't have to use bash for sysadmin
      yadm # Dotfile manager
      zfs # ZFS filesystem tools
      vim # Text editor
    ];
  };

  flake.modules.homeManager.cli = {
    config,
    pkgs,
    lib,
    ...
  }: {
    imports = with config.flake.modules; [
      homeManager.nushell
    ];

    home.sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      NH_FLAKE = config.home.homeDirectory + "/nix";
    };
  };
}
