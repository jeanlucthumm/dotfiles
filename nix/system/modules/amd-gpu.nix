{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      amdvlk
    ];
  };

  environment.systemPackages = with pkgs; [
    clinfo
  ];
}
