# Virtual lab -- boots the real host roles as networked QEMU VMs on one machine.
#
# The point is to close the loop between editing this repo and having evidence
# the edit works: a change (mine or an agent's) can be validated end to end
# before it ever reaches real hardware.
#
# Why this needs no host refactor: nixpkgs' test framework re-evaluates every
# node through `qemu-vm.nix`, which `mkVMOverride`s `fileSystems`,
# `swapDevices` and the bootloader. Disko's partition layout and the real
# `hardware-configuration.nix` are therefore ignored -- *provided* lab nodes
# import the role modules (`base`, `homeServer`, ...) rather than the
# `_host-specific` hardware trees. That split already exists here, which is the
# only reason this is cheap.
#
# The framework puts every node on vlan 1 as 192.168.1.<n> and writes the other
# nodes into /etc/hosts. That is the same subnet and the same short names as the
# real LAN, so subnet-scoped ACLs (transmission's `rpc-whitelist = 192.168.1.*`,
# netdata's `allow connections from`) behave exactly as they do IRL.
#
#   nix build .#checks.x86_64-linux.lab-home-lan   # run the assertions
#   nix run   .#lab-home-lan                       # interactive Python driver
#
# Needs a Linux host with /dev/kvm -- in practice `desktop`. Evaluates anywhere,
# so `nix eval` from the macbook still typechecks the whole lab.
fp @ {withSystem, ...}: let
  labSystem = "x86_64-linux";
  lib = fp.inputs.nixpkgs.lib;

  labs = withSystem labSystem ({pkgs, ...}: let
    M = fp.config.flake.modules.nixos;

    # Neutralises the parts of the real config that need hardware we don't have,
    # secrets we can't decrypt, or the public internet (test VMs are sandboxed
    # with no outbound route).
    labSafe = {
      # Wants a coordination server and an auth key.
      services.tailscale.enable = lib.mkForce false;
      # Peers are pinned to the real desktop/macbook device IDs; nothing here to
      # pair with, and it slows the boot down waiting.
      services.syncthing.enable = lib.mkForce false;
      # Every oci-container pulls its image from ghcr.io on start, which cannot
      # work in the sandbox. Drops Home Assistant.
      virtualisation.oci-containers.containers = lib.mkForce {};

      # Assertions below drive HTTP across the vlan.
      environment.systemPackages = [pkgs.curl];

      # No root password override: the config already sets one, and the
      # interactive driver reaches a root shell over the serial console anyway
      # (`server.shell_interact()`).
      virtualisation.memorySize = lib.mkDefault 2048;
    };

    mkNode = name: hostId: roles: extra:
      lib.mkMerge [
        {
          imports = roles ++ [labSafe];
          jl.system = labSystem;
          networking.hostName = name;
          networking.hostId = hostId;
          system.stateVersion = "24.05";
          home-manager.users.jeanluc.home.stateVersion = "24.05";
        }
        extra
      ];
  in {
    # Models the real home LAN: the always-on server and a workstation talking
    # to it over 192.168.1.0/24.
    #
    # Deliberately out of scope for now:
    #   - `secrets`: agenix decryption is gated on a YubiKey PIN + touch, which
    #     a headless VM cannot do. Needs test-only age identities to cover.
    #   - `graphical`: hyprland/niri/ly boot fine under qemu but need the
    #     `monitor` HM module populated, and little about them is assertable
    #     headlessly. Add a node for it when changing WM config specifically.
    #   - macbook: Darwin cannot be a node. Substitute a Linux client when a
    #     third party is needed.
    home-lan = lib.nixos.runTest {
      name = "lab-home-lan";
      hostPkgs = pkgs;
      # Must be set: it makes the framework own `nixpkgs.pkgs` on every node.
      # Left null, the framework instead defines `nixpkgs.system`, which
      # `readOnlyPkgs` (imported by `modules.nixos.base`) has removed -- the
      # eval aborts with "option `nixpkgs.system' does not exist".
      node.pkgs = pkgs;

      nodes = {
        server = mkNode "server" "1d9f895e" [M.base M.homeServer] {
          # Container + an Anthropic key that isn't on this box.
          services.hermes-agent.enable = lib.mkForce false;
          # Snapshots the `tank` zpool, which no lab node has.
          services.sanoid.enable = lib.mkForce false;
          # nginx + netdata + transmission together want more than the default.
          virtualisation.memorySize = 4096;
        };

        desktop = mkNode "desktop" "17646629" [M.base M.dev] {};
      };

      testScript = ''
        start_all()

        with subtest("both hosts boot"):
            server.wait_for_unit("multi-user.target")
            desktop.wait_for_unit("multi-user.target")

        with subtest("addressing matches the real LAN"):
            server.succeed("ip -4 addr show eth1 | grep -q 'inet 192.168.1.'")
            desktop.succeed("ping -c1 server")

        with subtest("sshd is up and refuses passwords"):
            server.wait_for_unit("sshd.service")
            server.wait_for_open_port(22)
            server.succeed(
                "grep -qi '^passwordauthentication no' /etc/ssh/sshd_config"
            )

        with subtest("nginx fronts netdata for LAN clients"):
            server.wait_for_unit("nginx.service")
            server.wait_for_unit("netdata.service")
            server.wait_for_open_port(80)
            desktop.succeed(
                "curl -sS -o /dev/null -w '%{http_code}' http://server/netdata/"
                " | grep -qE '^(200|30[12])$'"
            )

        with subtest("netdata is not reachable except through the proxy"):
            # It binds 127.0.0.1 and 19999 is not in the firewall allowlist.
            desktop.fail("curl -sS --max-time 5 http://server:19999/")

        with subtest("transmission rpc accepts LAN clients"):
            server.wait_for_unit("transmission.service")
            server.wait_for_open_port(9091)
            desktop.succeed("curl -sS -o /dev/null http://server:9091/transmission/web/")
      '';
    };
  });

  labNames = lib.attrNames labs;
in {
  # Mirrors deployment.nix: emit only under the system we actually run labs on,
  # so `nix flake check` on the macbook doesn't try to build x86_64-linux VMs.
  flake.checks.${labSystem} =
    lib.listToAttrs (map (n: lib.nameValuePair "lab-${n}" labs.${n}) labNames);

  # `nix run .#lab-<name>` drops into the test driver REPL with the VMs live,
  # for poking at a config by hand instead of asserting about it.
  flake.apps.${labSystem} =
    lib.listToAttrs (map (n:
      lib.nameValuePair "lab-${n}" {
        type = "app";
        program = "${labs.${n}.driverInteractive}/bin/nixos-test-driver";
      })
    labNames);
}
