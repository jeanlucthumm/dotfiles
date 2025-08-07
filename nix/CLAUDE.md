# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS/Nix flake configuration repository managing system and home configurations across multiple hosts (desktop, server, macbook, virtual). The configuration uses Home Manager for user-level configuration and follows a modular architecture.

## Common Commands

### Building and Switching Configurations

- **Rebuild system**: `nh os switch > /tmp/nh_build.log 2>/dev/null && echo "Build successful" || (echo "Build failed, showing output:" && cat /tmp/nh_build.log)` (NixOS) or `nh darwin switch > /tmp/nh_build.log 2>/dev/null && echo "Build successful" || (echo "Build failed, showing output:" && cat /tmp/nh_build.log)` (Darwin/macOS)
  - **IMPORTANT**: After making configuration changes, ALWAYS run this command to apply them
  - Use `nh os switch -u > /tmp/nh_build.log 2>/dev/null && echo "Build successful" || (echo "Build failed, showing output:" && cat /tmp/nh_build.log)` to update flake inputs as well
  - Stdout captured to tmp file, stderr discarded completely, output shown only on failure

- **Home Manager restart**: `sudo systemctl restart home-manager-jeanluc`

- **Deploy server**: `deploy .#server` (deploys remotely to server.lan)

- **Deploy all nodes**: `deploy .` (deploys all configured nodes)

- **Virtual VM**:

  - Build: `nixos-rebuild build-vm --flake .#virtual`
  - Run: `./result/bin/run-virtual-vm`
  - From non-NixOS: `nix run .#virtual-vm`

### Development Commands

- **Check deployment config**: `nix flake check` (validates deploy-rs configuration)

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

## Remote Server Commands

- For questions about the server config, you can run remote commands and get output with `ssh server.lan <cmd>`