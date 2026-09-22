# Fleet-wide Syncthing at the Home Manager layer. All state is here: `folders`
# is the catalog (identity only), `nodes` says per node which folders it carries,
# how, and where. A host only sets `jl.syncthing.enable`; its hostname picks its
# node. Runs as me so it can reach ~/obsidian etc. Identity (cert/key, hence
# device ID) lives in the daemon's state dir.
{jlib, ...}: let
  folders = {
    default = {
      id = "default";
      label = "Default Folder";
    };
    timewarrior = {
      id = "px27y-bxdsz";
      label = "Timewarrior";
    };
    obsidian = {
      id = "xyrfm-qkrya";
      label = "Obsidian";
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

  # Per folder: `path` relative to $HOME, `type` (default sendreceive).
  nodes = {
    desktop = {
      id = "4HQJBVL-WNGE7IM-NEFU2LX-LBRKDXV-VJOHS2C-C6UCUXH-3VQIJIZ-72MZYQ5";
      folders = {
        default.path = "Sync";
        timewarrior.path = ".timewarrior/data";
        obsidian.path = "obsidian/vault";
      };
    };
    macbook = {
      id = "PN3Q2MY-XB3YVM3-SV2BMT4-R4Q535H-Q7XV2LL-ETQKOZZ-VDF6MK3-2YNDAA6";
      folders = {
        default.path = "Sync";
        timewarrior.path = ".timewarrior/data";
        # iCloud-synced so the phone sees it too.
        obsidian.path = "Library/Mobile Documents/iCloud~md~obsidian/Documents/vault";
      };
    };
    # Backup-side replica: never originates changes.
    server = {
      id = "OSR5MAJ-K355Y22-LILPBYZ-5QV7OTN-FD3XCTW-HDZ5FTO-IYB3HUX-VXDSQAN";
      folders = {
        default = {
          path = "Sync";
          type = "receiveonly";
        };
        timewarrior = {
          path = ".timewarrior/data";
          type = "receiveonly";
        };
        obsidian = {
          path = "obsidian/vault";
          type = "receiveonly";
        };
      };
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
      host = osConfig.networking.hostName;
      me = nodes.${host} or {folders = {};};
      peers = removeAttrs nodes [host];
    in {
      options.jl.syncthing.enable = lib.mkEnableOption "this host's Syncthing node";

      config = lib.mkIf config.jl.syncthing.enable {
        # Bootstrap path: deploy, read the ID off the node, register it, redeploy.
        warnings =
          lib.optional (!(nodes ? ${host}))
          "syncthing: ${host} is not in the node table; it will run with no folders and peers will reject it until its ID is added";

        services.syncthing = {
          enable = true;
          overrideDevices = true;
          overrideFolders = true;
          settings = {
            devices = lib.mapAttrs (_: n: {inherit (n) id;}) peers;
            folders =
              lib.mapAttrs (name: f: let
                c = folders.${name};
              in {
                inherit (c) id label;
                path = "${config.home.homeDirectory}/${f.path}";
                type = f.type or "sendreceive";
                devices = lib.attrNames (lib.filterAttrs (_: n: n.folders ? ${name}) peers);
                ignorePatterns = c.ignorePatterns or [];
              })
              me.folders;
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
