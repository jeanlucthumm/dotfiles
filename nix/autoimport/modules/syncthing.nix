# Fleet-wide Syncthing at the Home Manager layer. All state is here: the
# device registry and, per folder, which devices carry it and how. A host
# only sets `jl.syncthing.enable`; its hostname picks its row.
# Runs as me so it can reach ~/obsidian etc. Identity (cert/key, hence
# device ID) lives in the daemon's state dir.
{jlib, ...}: let
  devices = {
    desktop = "4HQJBVL-WNGE7IM-NEFU2LX-LBRKDXV-VJOHS2C-C6UCUXH-3VQIJIZ-72MZYQ5";
    macbook = "PN3Q2MY-XB3YVM3-SV2BMT4-R4Q535H-Q7XV2LL-ETQKOZZ-VDF6MK3-2YNDAA6";
    server = "OSR5MAJ-K355Y22-LILPBYZ-5QV7OTN-FD3XCTW-HDZ5FTO-IYB3HUX-VXDSQAN";
  };

  # `path` is relative to $HOME. The server is the backup-side replica and
  # never originates changes.
  folders = {
    default = {
      id = "default";
      label = "Default Folder";
      path = "Sync";
      devices = {
        desktop = "sendreceive";
        macbook = "sendreceive";
        server = "receiveonly";
      };
    };
    timewarrior = {
      id = "px27y-bxdsz";
      label = "Timewarrior";
      path = ".timewarrior/data";
      devices = {
        desktop = "sendreceive";
        macbook = "sendreceive";
        server = "receiveonly";
      };
    };
    obsidian = {
      id = "xyrfm-qkrya";
      label = "Obsidian";
      path = "obsidian/vault";
      devices = {
        desktop = "sendreceive";
        macbook = "sendreceive";
        server = "receiveonly";
      };
      ignorePatterns = [
        ".devenv*"
        ".direnv"
        ".obsidian/workspace.json"
        ".obsidian/workspace-mobile.json"
        ".git"
        ".DS_Store"
        ".Trash-*"
      ];
    };
  };
in {
  flake.modules.homeManager.base = jlib.mkHomeManager {
    generic = {
      config,
      lib,
      osConfig ? {},
      ...
    }: let
      self = osConfig.networking.hostName;
      mine = lib.filterAttrs (_: f: f.devices ? ${self}) folders;
    in {
      options.jl.syncthing.enable = lib.mkEnableOption "this host's Syncthing node";

      config = lib.mkIf config.jl.syncthing.enable {
        # Bootstrap path: deploy, read the ID off the node, register it, redeploy.
        warnings = lib.optional (!(devices ? ${self}))
          "syncthing: ${self} is not in the device registry; it will run with no folders and peers will reject it until its ID is added";

        services.syncthing = {
          enable = true;
          overrideDevices = true;
          overrideFolders = true;
          settings = {
            devices = lib.mapAttrs (_: id: {inherit id;}) (removeAttrs devices [self]);
            folders = lib.mapAttrs (_: f: {
              inherit (f) id label;
              path = "${config.home.homeDirectory}/${f.path}";
              type = f.devices.${self};
              devices = lib.attrNames (removeAttrs f.devices [self]);
              ignorePatterns = f.ignorePatterns or [];
            })
            mine;
            options = {
              urAccepted = -1;
              localAnnounceEnabled = true;
              relaysEnabled = true;
            };
          };
        };
      };
    };
  };

  # HM can't open the firewall: sync transport plus local discovery.
  flake.modules.nixos.base = {
    config,
    lib,
    ...
  }: let
    anyNode = lib.any (u: u.jl.syncthing.enable or false) (lib.attrValues (config.home-manager.users or {}));
  in {
    networking.firewall = lib.mkIf anyNode {
      allowedTCPPorts = [22000];
      allowedUDPPorts = [22000 21027];
    };
  };
}
