# Config for a personal computer with graphical interface
{
  config,
  pkgs,
  zen-browser,
  ...
}: {
  # Fonts
  fonts.packages = with pkgs; [
    # builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome # for icons
  ];

  environment.systemPackages = [
    zen-browser.packages.${config.nixpkgs.system}.default
  ];
}
