#!/usr/bin/env bash
set -euo pipefail

# Restore server data from ZFS backups
# Run this AFTER deploying the Nix configuration on a new machine
#
# Prerequisites:
# - ZFS pool imported and mounted at /srv
# - Nix configuration deployed (creates service directories)
# - Backups available at /srv/backups

echo "=== Server Restore Script ==="
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root"
   exit 1
fi

# Verify backup directories exist
BACKUP_DIRS=("/srv/backups/home" "/srv/backups/homeassistant" "/srv/backups/plex")
for dir in "${BACKUP_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "Error: Backup directory not found: $dir"
        exit 1
    fi
done

echo "✓ All backup directories found"
echo

# Stop services
echo "Stopping services..."
systemctl stop plex.service || true
systemctl stop podman-homeassistant.service || true
echo "✓ Services stopped"
echo

# Restore home directory
echo "Restoring home directory..."
rsync -av --delete /srv/backups/home/ /home/jeanluc/
chown -R jeanluc:users /home/jeanluc
echo "✓ Home directory restored"
echo

# Restore Home Assistant
echo "Restoring Home Assistant data..."
rsync -av --delete /srv/backups/homeassistant/ /var/lib/home-assistant/
chown -R root:root /var/lib/home-assistant
echo "✓ Home Assistant data restored"
echo

# Restore Plex database
echo "Restoring Plex database..."
mkdir -p "/var/lib/plex/Plex Media Server/Plug-in Support/Databases"
rsync -av --delete /srv/backups/plex/ "/var/lib/plex/Plex Media Server/Plug-in Support/Databases/"
chown -R plex:media "/var/lib/plex/Plex Media Server/Plug-in Support/Databases"
echo "✓ Plex database restored"
echo

# Restart services
echo "Starting services..."
systemctl start plex.service
systemctl start podman-homeassistant.service
echo "✓ Services started"
echo

echo "=== Restore Complete ==="
echo
echo "Verify services are running:"
echo "  systemctl status plex"
echo "  systemctl status podman-homeassistant"
