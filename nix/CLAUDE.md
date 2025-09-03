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
- The server uses nushell. When running SSH commands to server.lan, use nushell syntax.

## Version Control with yadm

- **Semi-automated commit workflow**: 
  1. `yadm status` to see modified files
  2. `yadm ls-files --others --exclude-standard ~/nix/` to see untracked files in nix directory  
  3. `yadm diff` to review changes
  4. Group related changes by functional purpose:
     - Files implementing the same feature/fix should be committed together
     - Example: Adding git hooks to all templates = one commit for all template files
  5. **Manual handling required ONLY when**: A single file contains multiple unrelated changes mixed together
     - Tell user: "This file has multiple unrelated changes. Please use `yadm add -p <file>` to stage selectively"
  6. **For files with single functional changes**: Group and commit related files together
  7. `yadm add <files>` and `yadm commit -m "<scope>: <description>"`
  8. Examples of functional groupings:
     - All templates getting git hooks = "templates: add git hooks"
     - Claude model change = "claude: switch to opus model"
     - Documentation updates = "docs: add yadm workflow"
- **IMPORTANT**: Never run `yadm add -A` (this will add literally everything to yadm)
- **flake.lock handling**: flake.lock changes should not be independent commits. Bundle them with other commits
- **Commit message format**: `<program/scope>: <brief description>` (following existing pattern)

### Example commits:
- `claude: settings` - Claude configuration changes
- `nvim: better pasting` - Neovim paste improvements
- `nu: git abbreviations` - Nushell git alias updates
- `nix: add pkgs` - Package additions to Nix config
- `hypridle: increase timeouts` - Hypridle timeout adjustments
