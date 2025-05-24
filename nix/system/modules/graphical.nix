# Config for a personal computer with graphical interface
{
  config,
  pkgs,
  inputs,
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
    inputs.zen-browser.packages.${config.nixpkgs.system}.default
  ];
}
