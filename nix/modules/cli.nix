# CLI
{pkgs, ...}: {
  flake.modules.nixos.cli = {
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
}
