# Fleet-wide Syncthing at the Home Manager layer. One device registry and
# folder catalog; each host opts in with `jl.syncthing` and says only which
# catalog folders it carries and how. Runs as me so it can reach ~/obsidian etc.
{jlib, ...}: let
  devices = {
    desktop = "4HQJBVL-WNGE7IM-NEFU2LX-LBRKDXV-VJOHS2C-C6UCUXH-3VQIJIZ-72MZYQ5";
    macbook = "PN3Q2MY-XB3YVM3-SV2BMT4-R4Q535H-Q7XV2LL-ETQKOZZ-VDF6MK3-2YNDAA6";
    server = "OSR5MAJ-K355Y22-LILPBYZ-5QV7OTN-FD3XCTW-HDZ5FTO-IYB3HUX-VXDSQAN";
  };

  # `path` is relative to $HOME; hosts can override with an absolute path.
  catalog = {
    default = {
      id = "default";
      label = "Default Folder";
      path = "Sync";
    };
    timewarrior = {
      id = "px27y-bxdsz";
      label = "Timewarrior";
      path = ".timewarrior/data";
    };
    obsidian = {
      id = "xyrfm-qkrya";
      label = "Obsidian";
      path = "obsidian/vault";
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
      cfg = config.jl.syncthing;
      peers = lib.attrNames (removeAttrs devices [cfg.device]);
    in {
      options.jl.syncthing = {
        enable = lib.mkEnableOption "declarative Syncthing node";

        device = lib.mkOption {
          type = lib.types.enum (lib.attrNames devices);
          default = osConfig.networking.hostName;
          description = "This host's name in the device registry";
        };

        folders = lib.mkOption {
          default = {};
          description = "Catalog folders this host carries, keyed by catalog name";
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              type = lib.mkOption {
                type = lib.types.enum ["sendreceive" "sendonly" "receiveonly"];
                default = "sendreceive";
              };
              path = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Absolute path override; defaults to $HOME/<catalog path>";
              };
              devices = lib.mkOption {
                type = lib.types.listOf (lib.types.enum (lib.attrNames devices));
                default = peers;
                description = "Peers to share with; defaults to every other registered device";
              };
            };
          });
        };
      };

      config = lib.mkIf cfg.enable {
        services.syncthing = {
          enable = true;
          overrideDevices = true;
          overrideFolders = true;
          settings = {
            devices = lib.genAttrs peers (name: {id = devices.${name};});
            folders =
              lib.mapAttrs (name: f: let
                c = catalog.${name};
              in {
                inherit (c) id label;
                inherit (f) type devices;
                path =
                  if f.path != null
                  then f.path
                  else "${config.home.homeDirectory}/${c.path}";
                ignorePatterns = c.ignorePatterns or [];
              })
              cfg.folders;
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
