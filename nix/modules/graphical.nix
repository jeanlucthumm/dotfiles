# GUI
{pkgs, ...}: {
  flake.modules.nixos.graphical = {
    # Configure keymap in X11;
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
