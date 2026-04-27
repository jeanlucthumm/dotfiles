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
}
