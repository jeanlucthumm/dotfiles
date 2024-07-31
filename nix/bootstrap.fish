#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bash git

# Check if a hostname was provided
if test (count $argv) -eq 0
    echo "Error: Please provide a hostname."
    echo "Usage: ./bootstrap.fish <hostname>"
    exit 1
end

set hostname $argv[1]

function is_nixos
    test -f /etc/NIXOS
end

function is_darwin
    test (uname) = "Darwin"
end

git clone https://github.com/jeanlucthumm/dotfiles /tmp/dotfiles

# Determine the OS and run appropriate commands
if is_nixos
    echo "NixOS detected. Building configuration for $hostname..."
    sudo nixos-rebuild switch --flake /tmp/dotfiles/nix#$hostname
else if is_macos
    echo "macOS detected. Building configuration for $hostname..."
    nix run nix-darwin \
      --experimental-feature nix-command \
      --experimental-feature flakes \
      -- switch --flake /tmp/dotfiles/nix#$hostname
else
    echo "Error: Unsupported operating system."
    exit 1
end
