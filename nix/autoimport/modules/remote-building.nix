# Allows for darwin hosts to build linux stuff by delegating to server
fp: {
  flake.modules.darwin.base = {
    nix.distributedBuilds = true;

    nix.buildMachines = [
      {
        hostName = "server";
        sshUser = "nixremote";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub on the server
        # TODO: centralize this in pubkeys
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU9OSXRvL1J3TXhySW0zNkJRTXkveU5JZkF3R2dDbCswV1pmSDNXZmNDYmwgcm9vdEBzZXJ2ZXIK";
        supportedFeatures = [
          "big-parallel" # builds that scale to many cores (kernel, LLVM, Chromium, ...) — the one that matters for system closures
          "kvm" # builder has /dev/kvm; needed for VM-based builds
          "nixos-test" # can run NixOS VM integration tests (implies kvm)
          "benchmark" # benchmark derivations
        ];
      }
    ];
  };

  flake.modules.nixos.homeServer = {pkgs, ...}: {
    users.groups.nixremote = {};
    users.users.nixremote = {
      isNormalUser = true;
      group = "nixremote";
      description = "Remote Nix builds";
      shell = pkgs.bashInteractive;
      openssh.authorizedKeys.keys = [
        fp.config.flake.pubkeys.macbook.hostKey
      ];
    };

    nix.settings.trusted-users = ["nixremote"];
  };
}
