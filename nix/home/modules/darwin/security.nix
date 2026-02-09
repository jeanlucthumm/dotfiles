{pkgs, ...}: {
  home.packages = with pkgs; [
    openssh # FIDO2-capable SSH (macOS system SSH lacks libfido2)
  ];
}
