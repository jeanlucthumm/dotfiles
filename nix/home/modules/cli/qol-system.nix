# Quality of life tools that only make sense on a full local system
{pkgs, ...}: {
  home.packages = with pkgs; [
    notify # Cross-platform notifications
    ffmpeg # Media processing toolkit
    usbutils # USB utilities
  ];
}
