{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./theme.nix
  ];

  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

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
  services.blueman.enable = true;

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
    pls #           ls replacement
    fd #            find replacement
    zoxide #        cd replacement
    fzf #           Multi-purpose fuzzy finder
    libinput #      Inspect HID input
    jq #            CLI for json manipulation
    python3 #       The language python
    file #          Figure out what a certain file is
    nix-prefetch-git # Utility for populating nix fetchgit expressions
    tree #          List directory contents

    ## Desktop
    gammastep #     Redshifting at night
    cinnamon.nemo # File browser
    mako #          Notifications
    brightnessctl # Screen brightness controls
    wl-clipboard #  Copy paste in Wayland
    qutebrowser #   Keyboard-centric browser
    bitwarden-desktop # Password management
    signal-desktop #    Messaging
    grim #          Screenshots
    slurp #         For selecting screen regions
    pavucontrol #   GUI for PiperWire
    wev #           Shows keycodes in wayland
    ungoogled-chromium # Only used for Flutter dev
    hyprpaper #     Wallpaper for hyprland
    swayosd #       Responsive UI for changing volume and such
    xdg-utils #     Open files in right prorgram
    polkit_gnome #  UI for Polkit authentication
    neovide #       GUI wrapper for nvim

    ## Devex
    go #            The language Go
  ];

  # Programs with more config than systemPackages
  programs = {
    fish.enable = true; #         Shell

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
    hypridle.enable = true; #   Idle manager for Hyprland
    geoclue2.enable = true; #   Location services

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

    # Privilege escalation for user programs
    polkit.enable = true;

    sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  theme = {
    enable = true;
    name = "gruvbox";
    variant = "dark";
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # image and base16Scheme are set by theme module
  stylix = {
    enable = true;
    fonts = {
      monospace = {
        package = pkgs.nerdfonts.override {
          # Narrow down since all of nerdfonts is a lot.
          fonts = ["JetBrainsMono" "FiraCode"];
        };
        name = "JetBrainsMono Nerd Font";
      };
      sizes = {
        terminal = 11;
      };
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
