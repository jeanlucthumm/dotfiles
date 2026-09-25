{
  config,
  inputs,
  ...
}: {
  flake.nixosConfigurations."server" = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      homeServer
      agents
      {
        imports = [./_host-specific/server];

        networking.hostName = "server";
        networking.hostId = "1d9f895e";
        jl.system = "x86_64-linux";

        # TODO: figure out the secrets story for server
        # age.identityPaths = [
        #   "/home/jeanluc/.ssh/id_ed25519"
        # ];

        swapDevices = [
          {
            device = "/swapfile";
            size = 8 * 1024; # 8 GiB
          }
        ];

        users.users.root.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          macbook.fido2.auth
          phone
        ];

        users.users.jeanluc.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          macbook.fido2.auth
          phone
        ];

        services.atd.enable = true;

        # Syncthing runs as a user service; keep it up without a login session.
        users.users.jeanluc.linger = true;

        system.stateVersion = "24.05";

        home-manager.users.jeanluc = {
          jl.syncthing.enable = true;

          # Always-on remote control, driven from claude.ai/code and the app.
          jl.claude.rc.dirs = {
            dotfiles.dir = "/home/jeanluc/dotfiles";
            # Vault agents work in place: the tree is Syncthing-shared, so a
            # worktree would hide edits from every other device. A subdir
            # unit is a scoped agent: its own CLAUDE.md, .mcp.json and
            # .claude/settings.json live in the vault (synced, so identical
            # on every host), and additionalDirectories there opens the whole
            # vault for reading.
            chore = {
              dir = "/home/jeanluc/obsidian/vault/chore";
              spawn = "same-dir";
            };
          };

          # TODO directly use the reddit-easy-post flake output
          # home.packages = with pkgs; [
          #   reddit-easy-post # YAML to Reddit posting CLI
          # ];

          home.stateVersion = "24.05";
        };
      }
    ];
  };
}
