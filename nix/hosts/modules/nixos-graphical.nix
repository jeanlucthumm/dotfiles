# NixOS specific config for a personal computer with graphical interface
{pkgs, ...}: {
  systemd = {
    # Shows graphical prompts for privilege escalation.
    # This means a user can run programs with root access on demand and safely
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

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
}
