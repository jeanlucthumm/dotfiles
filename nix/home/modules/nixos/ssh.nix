# NixOS-specific SSH setup: agent socket env var and key preloading.
{lib, pkgs, ...}: {
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
}
