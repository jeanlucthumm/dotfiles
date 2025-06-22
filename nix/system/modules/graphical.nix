# NixOS specific config for a personal computer with graphical interface
{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Fonts
  fonts.packages = with pkgs; [
    # builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome # for icons
  ];

  environment.systemPackages = [
    inputs.zen-browser.packages.${config.nixpkgs.system}.default
  ];

  services = {
    # Audio management. Modern version of PulseAudio.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # Hyprland is a window manager.
  # The NixOS module enables critical components needed to run Hyprland properly, such as polkit,
  # xdg-desktop-portal-hyprland, graphics drivers, fonts, dconf, xwayland, and adding a proper
  # Desktop Entry to the Display Manager.
  programs.hyprland.enable = true;

  # Sway is a window manager.
  programs.sway.enable = true;
}
