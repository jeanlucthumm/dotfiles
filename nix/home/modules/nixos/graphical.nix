# NixOS specific GUI config
{
  inputs,
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;

  # Wayland image paste workaround for Kitty
  clip2path = pkgs.writeShellScriptBin "clip2path" ''
    set -e

    types=$(${pkgs.wl-clipboard}/bin/wl-paste --list-types)

    if grep -q '^text/' <<<"$types"; then
        ${pkgs.wl-clipboard}/bin/wl-paste --no-newline | ${pkgs.kitty}/bin/kitty @ --to unix:/tmp/kitty send-text --stdin
    elif grep -q '^image/' <<<"$types"; then
        ext=$(grep -m1 '^image/' <<<"$types" | cut -d/ -f2 | cut -d';' -f1)
        file="/tmp/clip_$(date +%s).''${ext}"
        ${pkgs.wl-clipboard}/bin/wl-paste > "$file"
        printf '%q' "$file" | ${pkgs.kitty}/bin/kitty @ send-text --stdin
    else
        ${pkgs.wl-clipboard}/bin/wl-paste --no-newline | ${pkgs.kitty}/bin/kitty @ send-text --stdin
    fi
  '';

  # Timewarrior auto stop/continue scripts for hypridle
  # Only continues if locked for less than 2 hours
  maxLockSeconds = 2 * 60 * 60; # 2 hours
  timewAutoStop = pkgs.writeShellScript "timew-auto-stop" ''
    if ${pkgs.timewarrior}/bin/timew get dom.active | grep -q "^1"; then
      ${pkgs.timewarrior}/bin/timew stop
      date +%s > /tmp/timew-auto-stopped
    fi
  '';
  timewAutoContinue = pkgs.writeShellScript "timew-auto-continue" ''
    if [ -f /tmp/timew-auto-stopped ]; then
      stopped_at=$(cat /tmp/timew-auto-stopped)
      now=$(date +%s)
      elapsed=$((now - stopped_at))
      if [ "$elapsed" -le ${toString maxLockSeconds} ]; then
        ${pkgs.timewarrior}/bin/timew continue
      fi
      rm /tmp/timew-auto-stopped
    fi
  '';
in {
  imports = [
    inputs.zen-browser.homeModules.beta
    ../../programs/hyprland.nix
    ../../programs/hyprlock.nix
    ../../programs/niri.nix
  ];

  home.packages = with pkgs; [
    signal-desktop # Encrypted messaging
    meld # Diff tool
    gammastep # Redshifting at night
    brightnessctl # Screen brightness controls
    wl-clipboard # Copy paste in Wayland
    bitwarden-desktop # Password management
    grim # Screenshots
    slurp # For selecting screen regions
    kooha # Screen recording for Wayland
    pavucontrol # GUI for PiperWire
    wev # Shows keycodes in wayland
    swayosd # Responsive UI for changing volume and such
    xdg-utils # Open files in right prorgram
    libnotify # Notifications
    libinput # Input device management
    discord # Chat
    neovide # NeoVim GUI
    hypridle # Idle management daemon

    lmstudio # LLM experimentation
    tor-browser # Privacy browser
    google-cloud-sdk # Google Cloud CLI
    chromium # For Dart dev and PWAs

    wasistlos # Chat (WhatsApp client)
    obsidian # Note taking
    smile # emoji picker
    transmission_4 # BitTorrent client

    clip2path # Wayland clipboard helper for Kitty
  ];

  programs = {
    mpv.enable = true;
    # Bottom bar
    waybar.enable = true;
    # Program launcher
    wofi = {
      enable = true;
      settings = {
        width = 420;
        height = 550;
        location = "center";
        allow_images = true; # Icons for entries
        allow_markup = true;
        prompt = "Program";
        matching = "fuzzy";
        no_actions = true; # No expandable list under certain programs
        halign = "fill";
        orientation = "vertical";
        insensitive = true;
        image_size = 28;
      };
    };
    # Keyboard-centric browser
    qutebrowser = {
      # Uses VCS dotfiles
      enable = true;
      loadAutoconfig = true;
    };

    # New-age Firefox based browser
    zen-browser = {
      enable = true;
    };

    nushell.shellAliases.nv = "neovide --fork";

    # Hack to allow copy pasting images in Claude Code with Kitty.
    kitty.keybindings = {
      "ctrl+v" = "launch --type=background --allow-remote-control --keep-focus ${clip2path}/bin/clip2path";
      "ctrl+enter" = "new_os_window_with_cwd";
    };
  };

  gtk = {
    enable = true;
    # TODO: add again once resolved: https://github.com/NixOS/nixpkgs/issues/380227
    # iconTheme = {
    #   name = "Tela-circle";
    #   package = pkgs.tela-circle-icon-theme;
    # };
    cursorTheme = {
      name = "Oreo Blue Cursors";
      package = pkgs.oreo-cursors-plus;
    };
  };

  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      pictures = "${homeDir}/media";
      music = "${homeDir}/media";
      videos = "${homeDir}/media";
      desktop = null;
      publicShare = null;
      templates = null;
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = ["zen-beta.desktop"];
        "x-scheme-handler/https" = ["zen-beta.desktop"];
        "text/html" = ["zen-beta.desktop"];
        "application/xhtml+xml" = ["zen-beta.desktop"];
        "application/pdf" = ["zen-beta.desktop"];
        "x-scheme-handler/magnet" = ["transmission-gtk.desktop"];
      };
    };

    desktopEntries = {
      qutebrowser-work = {
        name = "Qutebrowser (Work)";
        genericName = "Web Browser";
        comment = "A keyboard-driven, vim-like browser based on Python and Qt (Work Profile)";
        icon = "qutebrowser";
        type = "Application";
        categories = [
          "Network"
          "WebBrowser"
        ];
        exec = "qutebrowser --basedir ${configDir}/qutebrowser/profiles/work --untrusted-args %u";
        terminal = false;
        startupNotify = true;
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/xml"
          "application/rdf+xml"
          "image/gif"
          "image/webp"
          "image/jpeg"
          "image/png"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/qute"
        ];
        actions = {
          "new-window" = {
            name = "New Window";
            exec = "qutebrowser --basedir ${configDir}/qutebrowser/profiles/work";
          };
          "preferences" = {
            name = "Preferences";
            exec = "qutebrowser --basedir ${configDir}/qutebrowser/profiles/work qute://settings";
          };
        };
      };
    };
  };

  services = {
    swayosd.enable = true;
    # Redlight shifting at night
    gammastep = {
      enable = true;
      dawnTime = "06:00";
      duskTime = "22:00";
      temperature = {
        day = 6500;
        night = 3000;
      };
      provider = "geoclue2";
    };
    # Notification manager
    mako = {
      enable = true;
      settings = {
        markup = true;
        icons = true;
        borderRadius = 10;
        padding = "10";
      };
    };
    # Idle management daemon
    hypridle = {
      enable = true;
      # Fix race condition: start after niri sets WAYLAND_DISPLAY
      systemdTarget = "niri.service";
      settings = let
        dpmsCommand = m: msg: "niri msg output '${m.manufacturer} ${m.model} ${m.serial}' ${msg}";
        monitorOn = builtins.concatStringsSep " && " [
          (dpmsCommand config.monitors.primary "on")
          (dpmsCommand config.monitors.secondary "on")
          # Solves weird problem with hyprlock not showing up post screen sleep
          "sleep 7"
          "loginctl lock-session"
        ];
        monitorOff =
          (dpmsCommand config.monitors.primary "off")
          + " && "
          + (dpmsCommand config.monitors.secondary "off");
      in {
        general = {
          lock_cmd = "${timewAutoStop} ; pidof hyprlock || hyprlock > /tmp/hyprlock.log 2>&1";
          unlock_cmd = "${timewAutoContinue}";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = monitorOn;
        };
        listener = let
          lockTime = 10 * 60; # 10 minutes before lock
          dpmsTime = 40 * 60; # 40 minutes before display off
        in [
          {
            timeout = lockTime;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = dpmsTime;
            on-timeout = monitorOff;
            on-resume = monitorOn;
          }
        ];
      };
    };
  };
  home.sessionVariables = {
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
  };
}
