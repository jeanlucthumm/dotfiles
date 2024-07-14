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
      # Devex
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
    ];
  };

  # Home manager config. Manages user dotfiles.
  home-manager.users.jeanluc = {config, pkgs, ...}: {
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";

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
      taskwarrior = let
        configDir = "${config.xdg.configHome}/task";
      in {
        enable = true;
        dataLocation = "${config.xdg.dataHome}/task";
        extraConfig = ''
          uda.blocks.type=string
          uda.blocks.label=Blocks

          # Put contexts defined with `task context define` in this file
          include ${configDir}/context.config
          hooks.location=${configDir}/hooks
        '';
      };
    };
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

    # Desktop
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

    # Devex
    go #            The language Go
  ];

  # Programs with more config than systemPackages
  programs = {
    hyprland.enable = true;
    hyprlock.enable = true;
    waybar.enable = true;
    fish.enable = true;
    firefox = {
      enable = true;
      package = pkgs.firefox-bin;
    };
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
      settings = {
        default-cache-ttl = 14400;
        max-cache-ttl = 14400;
      };
    };
    ssh.startAgent = true;
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
    # Manages ssh and gpg keys. Enables ssh-add.
    gnome.gnome-keyring.enable = true;

    # Audio management. Modern version of PulseAudio.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
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
