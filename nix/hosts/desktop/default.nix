{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../default-nixos
    ./theme-setting.nix
  ];

  networking.hostName = "desktop"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  users.users.jeanluc = {
    isNormalUser = true;
    description = "Jean-Luc Thumm";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.fish;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
  };

  environment.systemPackages = with pkgs; [
    neovim
    yadm
    tmux
    fish
    git
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
