{
  flake.modules.nixos.amdGpu = {pkgs, ...}: {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };

    environment.systemPackages = with pkgs; [
      clinfo
    ];

    boot = {
      kernelParams = [
        # Disables AMDGPU Scatter/Gather display functionality to fix screen
        # flickering issues on Ryzen systems (especially 7000 series APUs).
        "amdgpu.sg_display=0"
      ];
    };
  };
}
