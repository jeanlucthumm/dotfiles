{config, ...}: let
  home = config.users.users.jeanluc.home;
  # Server device ID: OSR5MAJ-K355Y22-LILPBYZ-5QV7OTN-FD3XCTW-HDZ5FTO-IYB3HUX-VXDSQAN
in {
  services.syncthing = {
    enable = true;
    user = "jeanluc";
    group = "users";
    dataDir = home;
    configDir = "${home}/.config/syncthing";
    openDefaultPorts = true;

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        desktop = {
          id = "4HQJBVL-WNGE7IM-NEFU2LX-LBRKDXV-VJOHS2C-C6UCUXH-3VQIJIZ-72MZYQ5";
        };
        macbook = {
          id = "PN3Q2MY-XB3YVM3-SV2BMT4-R4Q535H-Q7XV2LL-ETQKOZZ-VDF6MK3-2YNDAA6";
        };
      };

      folders = {
        "default" = {
          path = "${home}/Sync";
          devices = ["desktop" "macbook"];
          type = "receiveonly";
          label = "Default Folder";
        };
        "px27y-bxdsz" = {
          path = "${home}/.timewarrior/data";
          devices = ["desktop" "macbook"];
          type = "receiveonly";
          label = "Timewarrior";
        };
        "xyrfm-qkrya" = {
          path = "${home}/obsidian/vault";
          devices = ["desktop" "macbook"];
          type = "receiveonly";
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

      options = {
        urAccepted = -1;
        localAnnounceEnabled = true;
        relaysEnabled = true;
      };
    };
  };

  services.nginx.virtualHosts."server".locations."/syncthing/" = {
    proxyPass = "http://127.0.0.1:8384/";
    proxyWebsockets = true;
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';
  };
}
