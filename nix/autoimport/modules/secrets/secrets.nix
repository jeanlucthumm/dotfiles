{
  config,
  inputs,
  jlib,
  ...
}: {
  flake.modules.generic.secrets = {
    age = {
      # TODO rel paths broken
      secrets = {
        openai = {
          file = ./_age/jeanluc-openai.age;
          mode = "400";
        };
        anthropic = {
          file = ./_age/jeanluc-anthropic.age;
          mode = "400";
        };
        notion = {
          file = ./_age/jeanluc-notion.age;
          mode = "400";
        };
        taskwarrior = {
          file = ./_age/jeanluc-taskwarrior.age;
          mode = "400";
          # Workaround since taskwarrior config does not support shell eval
          # And Darwin `path` includes it.
          path = "/tmp/jeanluc-taskwarrior.age";
          # Workaround for lack of lchmod on Darwin, so symlinks wouldn't have correct `mode`.
          symlink = false;
        };
      };
      # identityPaths set per-host (YubiKey identity file differs per device)
    };
  };

  flake.modules.nixos.secrets = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age-plugin-yubikey
    ];

    age = {
      # TODO this is duplicated throughout this file
      # Inline PATH so age finds the plugin and can prompt for PIN interactively
      ageBin = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";
    };

    home-manager.sharedModules = [config.flake.modules.homeManager.secrets];
  };

  flake.modules.darwin.secrets = {pkgs, ...}: {
    imports = [
      inputs.agenix.darwinModules.default
    ];

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age-plugin-yubikey
    ];

    home-manager.sharedModules = [config.flake.modules.homeManager.secrets];
  };

  flake.modules.homeManager.secrets = {
    pkgs,
    lib,
    ...
  }:
    jlib.mkHomeManager {
      generic = {
        imports = [inputs.agenix.homeManagerModules.default];
        home.packages = let
          s = config.flake.modules.generic.secrets;
          makeKeyGetter = path: ''
            umask 077 # Ensure any possible temp files are private
            cat ${path}
          '';
        in
          with pkgs; [
            # Key Getters
            (pkgs.writeShellScriptBin "get-key-anthropic" (makeKeyGetter s.anthropic.path))
            (pkgs.writeShellScriptBin "get-key-openai" (makeKeyGetter s.openai.path))
            (pkgs.writeShellScriptBin "get-key-notion" (makeKeyGetter s.notion.path))

            age # Age encryption tool
            pinentry-tty # Enter password in terminal
          ];
      };

      darwin = let
        args = config.flake.modules.homeManager.secrets.launchd.agents.activate-agenix.config.ProgramArguments;
        # Agenix sets ProgramArguments = [ mountingScript ]; home-manager wraps
        # it in the plist but the config value is the unwrapped nix store path.
        mountScript = builtins.head args;
      in {
        age.package = pkgs.writeShellScriptBin "age" ''
          export PATH="${lib.makeBinPath [pkgs.age-plugin-yubikey]}:$PATH"
          exec ${pkgs.age}/bin/age "$@"
        '';

        launchd.agents.activate-agenix.config = {
          RunAtLoad = lib.mkForce false;
          KeepAlive = lib.mkForce {};
        };

        home.packages = [
          (pkgs.writeShellScriptBin "delock" ''
            exec ${mountScript}
          '')
        ];
      };
    };
}
