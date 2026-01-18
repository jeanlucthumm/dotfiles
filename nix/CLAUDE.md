# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS/Nix flake configuration repository managing system and home configurations across multiple hosts (desktop, server, macbook, virtual). The configuration uses Home Manager for user-level configuration and follows a modular architecture.

## Common Commands

### Building and Switching Configurations

- **Home Manager restart**: `sudo systemctl restart home-manager-jeanluc`

- **Deploy server**: `deploy .#server` (deploys remotely to server.lan)

- **Deploy all nodes**: `deploy .` (deploys all configured nodes)

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

## General notes

- User primarily uses nushell for interactive use. Config is located in `home/programs/nushell/`
- **Use `manix` to search for Nix packages and options**:
  - `manix <query>` - searches nixpkgs packages, NixOS options, Home Manager options, nix-darwin options
  - `manix <query> --source nixpkgs_tree` - search only packages
  - `manix <query> --source hm_options` - search only Home Manager options
  - `manix <query> --source nd_options` - search only nix-darwin options

## Version Control with yadm

- **Semi-automated commit workflow**:
  1. `yadm status` to see modified files
  1. `yadm ls-files --others --exclude-standard ~/nix/` to see untracked files in nix directory
  1. `yadm diff` to review changes
  1. Group related changes by functional purpose:
     - Files implementing the same feature/fix should be committed together
     - Example: Adding git hooks to all templates = one commit for all template files
  1. **Manual handling required ONLY when**: A single file contains multiple unrelated changes mixed together
     - Tell user: "This file has multiple unrelated changes. Please use `yadm add -p <file>` to stage selectively"
  1. **For files with single functional changes**: Group and commit related files together
  1. `yadm add <files>` and `yadm commit -m "<scope>: <description>"`
  1. Examples of functional groupings:
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

