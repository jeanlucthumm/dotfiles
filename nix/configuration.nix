{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "laptop";
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Users
  users.users.jeanluc = {
    isNormalUser = true;
    description = "Jean-Luc Thumm";
    extraGroups = [
      "networkmanager" #  manage internet connections with nmcli
      "wheel" #           access sudo
      "adbusers" #        access adb for android dev
      "audio" #           access to pulseaudio devices
    ];
    shell = pkgs.fish;

    # User specific packages. System wide packages are in
    # environment.systemPackages and programs.
    packages = with pkgs; [
      timewarrior #       time tracker
      grc #               colorizes CLI output

      ## Devex
      sumneko-lua-language-server
      gopls
      black
      delve
      impl
      gotools
      luajitPackages.jsregexp
      mdformat
      clang-tools
      buf
      buf-language-server
      prettierd
      isort
      actionlint
      mypy
      tree-sitter
      nodejs_22
      ripgrep
      flutter
      android-tools
      statix
      alejandra
    ];
  };

  # Home manager config. Manages user dotfiles.
  home-manager.users.jeanluc = {
    config,
    pkgs,
    ...
  }: let
    isLinux = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;
    isArch = builtins.pathExists "/etc/arch-release";
    homeDir = config.home.homeDirectory;
    configDir = config.xdg.configHome;
  in {
    programs = {
      kitty = {
        enable = true;
        font.name = "JetBrainsMono Nerd Font";
        shellIntegration.enableFishIntegration = true;
        shellIntegration.mode = "no-cursor";
        theme = "zenbones_dark";
        settings = {
          enable_audio_bell = true;
          window_padding_width = 8;
          allow_remote_control = false;
          repaint_delay = 6;
          input_delay = 1;
          cursor_shape = "blocK";
          macos_option_as_alt = true;
          scrollback_pager = "nvim -c 'set ft=sh' -";
          paste_actions = "quote-urls-at-prompt";
        };
      };
      taskwarrior = {
        enable = true;
        dataLocation = "${config.xdg.dataHome}/task";
        extraConfig = ''
          uda.blocks.type=string
          uda.blocks.label=Blocks
          news.version=2.6.0

          # Put contexts defined with `task context define` in this file
          include ${configDir}/task/context.config
          hooks.location=${configDir}/task/hooks
        '';
      };
      fish = {
        enable = true;
        plugins = with pkgs.fishPlugins; [
          {
            name = "fzf";
            src = fzf;
          }
          {
            name = "grc";
            src = grc;
          }
        ];
        shellAbbrs = {
          g = "git";
          t = "task";
          docker = "sudo docker";
          ga = "git a";
          gm = "git com";
          gs = "git stat";
          gt = "git tree";
          gd = "git d";
          gda = "git a && git d";
          clear-nvim-swap = "rm -rf ~/.local/state/nvim/swap";
          ta = "task active";
          tr = "task ready";
          tdesc = "tprop description";
          day = "timew day";
          acc = "task end.after:today completed";
        };
        # Like shellAbbrs but doesn't auto expand when typing
        shellAliases = {
          vim = "nvim";
          cat = "bat";
          ls = "pls";
          ssh = "TERM=xterm-256color /usr/bin/ssh";
        };
        interactiveShellInit = ''
          # Jump around words easier
          bind \ch backward-word
          bind \cl forward-word

          # Theme
          set -g theme_nerd_fonts yes
          set -g theme_color_scheme dark
          fish_config theme choose Lava

          if is_ssh_session; and not set -q TMUX
            exec tmux attach
          end
        '';
      };
    };

    home = {
      sessionVariables =
        {
          EDITOR = "${pkgs.neovim}/bin/nvim";
          MANPAGER = "sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'";
          CONF = configDir;
          CODE = "${homeDir}/Code";
          # Shell prompts tend to manage venvs themselves
          VIRTUAL_ENV_DISABLE_PROMPT = 1;
        }
        // (
          if isLinux
          then {
            ANDROID_SDK_ROOT = "${homeDir}/Android/Sdk";
            ANDROID_HOME = config.home.sessionVariables.ANDROID_SDK_ROOT;
            CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}";
          }
          else if isDarwin
          then {
            ANDROID_HOME = "/Users/${config.home.username}/Library/Android/sdk";
          }
          else {}
        );

      # Extra stuff to add to $PATH
      sessionPath =
        if isDarwin
        then [
          # homebrew puts all its stuff in this directory instead
          # of /usr/bin or otherwise
          "/opt/homebrew/bin"
        ]
        else [];

      preferXdgDirectories = true;
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
    };

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic sytem wide packages
  environment.systemPackages = with pkgs; [
    manix #         CLI for nix docs
    neovim #        IDE (tExT eDiToR)
    tmux #          Terminal multiplexer
    yadm #          Dotfile manager
    gh #            GitHub CLI
    git #           Version control system
    git-lfs #       Git extension for large files
    gnupg #         GNU Privacy Guard
    pinentry-tty #  Enter password in terminal
    gnumake #       Build automation tool
    delta #         Pretty diffs
    bat #           Cat replacement
    gcc #           GNU Compiler Collection
    wofi #          Program launcher
    pls #           ls replacement
    fd #            find replacement
    fzf #           Multi-purpose fuzzy finder
    libinput #      Inspect HID input
    jq #            CLI for json manipulation
    python3 #        The language python

    ## Desktop
    gammastep #     Redshifting at night
    cinnamon.nemo # File browser
    mako #          Notifications
    brightnessctl # Screen brightness controls
    wl-clipboard #  Copy paste in Wayland
    kitty #         Terminal
    qutebrowser #   Keyboard-centric browser
    bitwarden-desktop # Password management
    signal-desktop #    Messaging
    grim #          Screenshots
    slurp #         For selecting screen regions
    pavucontrol #   GUI for PiperWire
    wev #           Shows keycodes in wayland
    ungoogled-chromium # Only used for Flutter dev

    ## Devex
    go #            The language Go
  ];

  # Programs with more config than systemPackages
  programs = {
    fish.enable = true;

    # Manages GPG keys for signing stuff like git commits
    gnupg.agent = {
      enable = true;
      # Use the CLI to provide key passwords
      pinentryPackage = pkgs.pinentry-tty;
      settings = {
        # Don't ask for password within given time
        default-cache-ttl = 14400;
        max-cache-ttl = 14400;
      };
    };
    # Manages SSH keys so you can do `ssh-add`
    ssh.startAgent = true;

    ## Desktop
    firefox = {
      enable = true;
      package = pkgs.firefox-bin;
    };
    hyprland.enable = true; #     Window manager
    hyprlock.enable = true; #     Lockscreen
    waybar.enable = true; #       Bottom bar
    seahorse.enable = true; #     GUI for gnome-keyring
  };

  # Fonts
  fonts.packages = with pkgs; [
    # Nerd fonts are patched fonts that add more icons.
    # Neovim makes use of this.
    (nerdfonts.override {
      # Narrow down since all of nerdfonts is a lot.
      fonts = ["JetBrainsMono" "FiraCode"];
    })
    font-awesome # for icons
  ];

  # Services
  services = {
    # Manages program secrets.
    gnome.gnome-keyring.enable = true;

    # Audio management. Modern version of PulseAudio.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security = {
    # Unlock gnome-keyring on tty login
    pam.services.login.enableGnomeKeyring = true;

    sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05";
}
