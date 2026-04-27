# GUI
{
  flake.modules.nixos.graphical = {
    # Configure keymap in X11;
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };

  flake.modules.darwin.graphical = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      raycast
    ];
  };

  flake.modules.homeManager.graphical = {pkgs, ...}: let
    # `clip` comes from the cli profile (always co-imported at host level).
    copy-last-cmd = pkgs.writeShellScriptBin "copy-last-cmd" ''
      cmd=$(${pkgs.nushell}/bin/nu -c 'history | last | get command')
      output=$(kitty @ get-text --extent last_non_empty_output)
      printf '$ %s\n%s' "$cmd" "$output" | clip
    '';
  in {
    home.packages = with pkgs; [
      copy-last-cmd
      notify # Cross-platform notifications
      ffmpeg # Media processing toolkit
      usbutils # USB utilities
    ];
  };
}
