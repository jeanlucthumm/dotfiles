# Config for a personal computer with graphical interface
{pkgs, ...}: {
  # Fonts
  fonts.packages = with pkgs; [
    # Nerd fonts are patched fonts that add more icons.
    # Neovim makes use of this.
    (nerdfonts.override {
      # Narrow down since all of nerdfonts is a lot.
      fonts = ["JetBrainsMono" "FiraCode"];
    })
    font-awesome # for icons
  ];
}
