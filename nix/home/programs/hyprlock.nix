{
  pkgs,
  config,
  lib,
  ...
}:
with config.lib.stylix.colors; let
  primary = with config.monitors.primary; "${manufacturer} - ${model}";
in {
  home.packages = with pkgs; [
    nerd-fonts.geist-mono
  ];

  programs.hyprlock = {
    enable = true;
    settings = {
      background =
        [
          {
            monitor = primary;
            path = "${config.home.homeDirectory}/media/gruvbox_cat.png";
            blur_size = 4;
            blur_passes = 3;
            noise = 0.0117;
            contrast = 1.3;
            brightness = 0.8;
            vibrancy = 0.21;
            vibrancy_darkness = 0.0;
          }
        ]
        ++ lib.optionals (config.monitors.secondary != null) [
          {
            monitor = with config.monitors.secondary; "${manufacturer} - ${model}";
            color = "rgb(000000)";
          }
        ];

      label = [
        # Hours
        {
          monitor = primary;
          text = ''cmd[update:1000] echo "<b><big> $(date +"%H") </big></b>"'';
          color = "rgb(${base0C})";
          font_size = 112;
          font_family = "Geist Mono 10";
          shadow_passes = 3;
          shadow_size = 4;
          position = "0, 220";
          halign = "center";
          valign = "center";
        }
        # Minutes
        {
          monitor = primary;
          text = ''cmd[update:1000] echo "<b><big> $(date +"%M") </big></b>"'';
          color = "rgb(${base0C})";
          font_size = 112;
          font_family = "Geist Mono 10";
          shadow_passes = 3;
          shadow_size = 4;
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        # Today
        {
          monitor = primary;
          text = ''cmd[update:18000000] echo "<b><big> "$(date +'%A')" </big></b>"'';
          color = "rgb(${base05})";
          font_size = 22;
          font_family = "JetBrainsMono Nerd Font 10";
          position = "0, -20";
          halign = "center";
          valign = "center";
        }
        # Week
        {
          monitor = primary;
          text = ''cmd[update:18000000] echo "<b> "$(date +'%d %b')" </b>"'';
          color = "rgb(${base05})";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font 10";
          position = "0, -60";
          halign = "center";
          valign = "center";
        }
        # Weather
        {
          monitor = primary;
          text = ''cmd[update:18000000] echo "<b>Feels like<big> $(curl -s 'wttr.in?format=%t&m' | tr -d '+') </big></b>"'';
          color = "rgb(${base05})";
          font_size = 18;
          font_family = "Geist Mono 10";
          position = "0, 40";
          halign = "center";
          valign = "bottom";
        }
      ];

      input-field = [
        {
          monitor = primary;
          size = "250, 50";
          outline_thickness = 3;
          dots_size = 0.26;
          dots_spacing = 0.64;
          dots_center = true;
          dots_rounding = -1;
          rounding = 22;
          outer_color = "rgb(${base00})";
          inner_color = "rgb(${base00})";
          font_color = "rgb(${base0C})";
          fade_on_empty = true;
          placeholder_text = "<i>Password...</i>";
          position = "0, 120";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };
}
