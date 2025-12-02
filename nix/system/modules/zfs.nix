# ZFS scrub configuration for tank pool
# Runs monthly, but only during daytime to avoid HDD noise at night
{pkgs, ...}: let
  startHour = "09"; # Resume/start scrubbing
  endHour = "22"; # Pause scrubbing
in {
  # Disable NixOS auto-scrub, we manage it ourselves
  services.zfs.autoScrub.enable = false;

  # Start scrub on 1st of month
  systemd.services.zfs-scrub-start = {
    description = "Start monthly ZFS scrub";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.zfs}/bin/zpool scrub tank";
    };
  };
  systemd.timers.zfs-scrub-start = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-01 ${startHour}:00:00";
      Persistent = true;
    };
  };

  # Pause scrub at night
  systemd.services.zfs-scrub-pause = {
    description = "Pause ZFS scrub for nighttime";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.zfs}/bin/zpool scrub -p tank";
    };
  };
  systemd.timers.zfs-scrub-pause = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* ${endHour}:00:00";
      Persistent = true;
    };
  };

  # Resume scrub in morning - only if paused
  systemd.services.zfs-scrub-resume = {
    description = "Resume ZFS scrub for daytime";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'if ${pkgs.zfs}/bin/zpool status tank | grep -q \"scrub paused\"; then ${pkgs.zfs}/bin/zpool scrub tank; fi'";
    };
  };
  systemd.timers.zfs-scrub-resume = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* ${startHour}:00:00";
      Persistent = true;
    };
  };
}
