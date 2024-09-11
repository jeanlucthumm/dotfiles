{ config, pkgs, ... }: {
  imports = [
    ../default-nixos
    ./hardware-configuration.nix
    ./theme-setting.nix
  ];

  networking.hostName = "virtualbox";

  users.users.jeanluc = {
    isNormalUser = true;
    description = "Jean-Luc Thumm";
    extraGroups = [
      "networkmanager" # manage internet connections with nmcli
      "wheel" # access sudo
      "adbusers" # access adb for android dev
      "audio" # access to pulseaudio devices
    ];
    shell = pkgs.fish;
    initialPassword = "password";
  };
}
