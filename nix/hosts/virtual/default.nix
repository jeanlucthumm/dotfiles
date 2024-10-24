{
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  imports = [
    ../default-nixos
    ./hardware-configuration.nix
    ./theme-setting.nix
    "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
  ];

  networking.hostName = "virtual";

  users.mutableUsers = false;
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
    hashedPassword = "$6$pRLl.dFdqKAg8ww3$U9N4VWBVNci1me8yJD1Pv2sxuX484PhIaQwLcmsTLX3y/KNLAxm6x0HQioOHA2srM5u4/.99Vc/YtkdvxMF5.0";
  };

  services.qemuGuest.enable = true;

  boot.initrd.kernelModules = ["virtio_gpu" "amdgpu"];

  virtualisation.qemu = {
    options = [
      "-device virtio-vga-gl"
      "-display sdl,gl=on,show-cursor=off"
      "-audio pa,model=hda"
    ];
    guestAgent.enable = true;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    LIBGL_ALWAYS_SOFTWARE = "1";
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
