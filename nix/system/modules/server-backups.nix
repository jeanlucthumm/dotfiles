{pkgs, ...}: {
  # Systemd services to backup critical data to ZFS pool

  environment.systemPackages = with pkgs; [
    rsync
  ];

  # Home directory backup
  systemd.services.home-backup = {
    description = "Backup home directory to ZFS pool";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.rsync}/bin/rsync -av --delete --include '/.ssh/' --include '/.ssh/**' --include '/.gnupg/' --include '/.gnupg/**' --exclude '/.*' --exclude 'restore.sh' --exclude '.cache' --exclude '.npm' --exclude '.nix-defexpr' --exclude '.nix-profile' --exclude '.nix-channels' /home/jeanluc/ /srv/backups/home/";
    };
  };

  systemd.timers.home-backup = {
    description = "Weekly home directory backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Sun *-*-* 14:00:00";
      Persistent = true;
    };
  };

  # Home Assistant backup
  systemd.services.homeassistant-backup = {
    description = "Backup Home Assistant data to ZFS pool";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.rsync}/bin/rsync -av --delete /var/lib/home-assistant/ /srv/backups/homeassistant/";
    };
  };

  systemd.timers.homeassistant-backup = {
    description = "Weekly Home Assistant backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Sun *-*-* 14:05:00";
      Persistent = true;
    };
  };

  # Plex database backup
  systemd.services.plex-backup = {
    description = "Backup Plex database to ZFS pool";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.rsync}/bin/rsync -av --delete '/var/lib/plex/Plex Media Server/Plug-in Support/Databases/' /srv/backups/plex/";
    };
  };

  systemd.timers.plex-backup = {
    description = "Weekly Plex database backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Sun *-*-* 14:10:00";
      Persistent = true;
    };
  };

  # Ensure backup directories exist
  systemd.tmpfiles.rules = [
    "d /srv/backups/home 0755 jeanluc users -"
    "d /srv/backups/homeassistant 0755 root root -"
    "d /srv/backups/plex 0755 root root -"
  ];
}
