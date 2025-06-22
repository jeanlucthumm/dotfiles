# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS/Nix flake configuration repository managing system and home configurations across multiple hosts (desktop, server, macbook, virtual). The configuration uses Home Manager for user-level configuration and follows a modular architecture.

## Common Commands

### Building and Switching Configurations

- **NixOS rebuild**: `sudo nixos-rebuild switch --flake .#<hostname>`
  - Available hostnames: `desktop`, `server`, `virtual`
  - Current Makefile uses `laptop` (may need updating)

- **Darwin rebuild**: `nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake '.#macbook'`

- **Home Manager restart**: `sudo systemctl restart home-manager-jeanluc`

- **Virtual VM**: 
  - Build: `nixos-rebuild build-vm --flake .#virtual`
  - Run: `./result/bin/run-virtual-vm`
  - From non-NixOS: `nix run .#virtual-vm`

### Development Commands

- **Make rebuild**: `make rebuild` (uses flake `.#laptop`)
- **Make qemu_serial**: `make qemu_serial` (runs VM with serial console)

## Architecture

### Directory Structure

- **`flake.nix`**: Main flake configuration defining all system configurations
- **`system/`**: NixOS system-level configurations
  - `hosts/`: Host-specific configurations (desktop, server, macbook, virtual)
  - `modules/`: Reusable NixOS system modules
- **`home/`**: Home Manager configurations
  - `hosts/`: Host-specific home configurations  
  - `modules/`: Logical collections of home configuration (e.g., CLI, graphical)
  - `programs/`: Individual program configurations
- **`secrets/`**: Age-encrypted secrets managed by agenix

### Configuration Philosophy

- **Modularity**: Host configurations should primarily import from modules directories
- **No duplication**: Code should be shared via modules rather than duplicated
- **Separation**: System modules (NixOS) vs home modules (Home Manager) vs program configs

### Key Dependencies

- **Home Manager**: User-level configuration management
- **Stylix**: System-wide theming
- **agenix**: Secret management
- **nix-darwin**: macOS system configuration

### Host Types

- **desktop**: Full graphical NixOS system (x86_64-linux)
- **server**: Headless 24/7 system (x86_64-linux)  
- **macbook**: Darwin/macOS configuration
- **virtual**: VM configuration for testing

## Secret Management

Secrets are managed using agenix with SSH public keys defined in `secrets/secrets.nix`. Available secrets include API keys for OpenAI, Anthropic, Tavily, and Codestral.