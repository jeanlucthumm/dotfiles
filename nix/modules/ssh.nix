# SSH
fps: {
  flake.modules.nixos.base = {lib, ...}: {
    services.openssh = {
      enable = true;
      # Forces SSH keys
      settings.PasswordAuthentication = false;
    };
    networking.firewall.allowedTCPPorts = [22];

    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
  };

  flake.modules.darwin.base = {
    # SSH server configuration
    services.openssh = {
      enable = true;
      extraConfig = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
      '';
    };
  };

  flake.modules.homeManager.base = {
    lib,
    pkgs,
    ...
  }:
    fps.mkHomeManager pkgs {
      generic = {
        programs.ssh.enableDefaultConfig = false;
        programs.ssh.matchBlocks."*" = {
          controlMaster = "auto";
          controlPath = "~/.ssh/sockets/%r@%h-%p";
          controlPersist = "4h";
        };
      };

      nixos = {
        programs.nushell.environmentVariables.SSH_AUTH_SOCK = lib.hm.nushell.mkNushellInline ''$"($env.XDG_RUNTIME_DIR)/ssh-agent"'';

        # Pre-load SSH key handles into agent at login so all programs can use them.
        systemd.user.services.ssh-add-keys = {
          Unit = {
            Description = "Load SSH keys into agent";
            After = ["ssh-agent.service"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_sk_auth";
            Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
          };
          Install.WantedBy = ["default.target"];
        };
      };

      darwin = {
        home.packages = [
          pkgs.openssh # FIDO2-capable SSH (macOS system SSH lacks libfido2)
        ];

        # Use nix-provided ssh-agent instead of macOS launchd agent (which lacks SK/FIDO2 support)
        services.ssh-agent.enable = true;

        # Point system-wide SSH_AUTH_SOCK to FIDO2-capable agent, preload auth key.
        launchd.agents.ssh-fido2-setup = {
          enable = true;
          config = {
            ProgramArguments = [
              "/bin/bash"
              "-c"
              ''
                SOCK="$(getconf DARWIN_USER_TEMP_DIR)ssh-agent"
                launchctl setenv SSH_AUTH_SOCK "$SOCK"
                while [ ! -S "$SOCK" ]; do sleep 0.5; done
                export SSH_AUTH_SOCK="$SOCK"
                ${pkgs.openssh}/bin/ssh-add "$HOME/.ssh/id_ed25519_sk_auth" 2>/dev/null
              ''
            ];
            RunAtLoad = true;
            KeepAlive = false;
          };
        };
      };
    };
}
