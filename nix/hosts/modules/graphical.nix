# Config for a personal computer with graphical interface
{pkgs, ...}: {
  # Fonts
  fonts.packages = with pkgs; [
    # builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome # for icons
  ];
}
