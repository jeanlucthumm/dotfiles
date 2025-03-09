{config, ...}: let
  theme = config.theme;
in {
  programs.taskwarrior = {
    colorTheme =
      if theme.darkMode
      then ./themes/dark-256.theme
      else ./themes/light-256.theme;
  };
}
