{...}: {
  boot = {
    loader = {
      # Allows NixOS to modify EFI variables, e.g. boot entries and order.
      efi.canTouchEfiVariables = true;
      # Bootloader
      systemd-boot = {
        enable = true;
        # CLI at the UEFI level. So you can interact with boot process to
        # fix things if neccessary.
        edk2-uefi-shell.enable = true;
        # Limits the amount of previous generations in the boot menu. If this is set to unlimited,
        # the /boot partition can fill up.
        configurationLimit = 20;
      };
    };
    supportedFilesystems = ["zfs" "ntfs"];
  };
}
