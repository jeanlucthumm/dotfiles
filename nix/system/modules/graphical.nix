# NixOS specific config for a personal computer with graphical interface
{pkgs, ...}: {
  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome # for icons
  ];

  services = {
    # Audio management. Modern version of PulseAudio.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    displayManager.ly = {
      enable = true;
    };
  };

  # Hyprland is a window manager.
  # The NixOS module enables critical components needed to run Hyprland properly, such as polkit,
  # xdg-desktop-portal-hyprland, graphics drivers, fonts, dconf, xwayland, and adding a proper
  # Desktop Entry to the Display Manager.
  programs.hyprland.enable = true;
  programs.niri.enable = true;

  # Sway is a window manager.
  programs.sway.enable = true;
}
