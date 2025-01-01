{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.aichat;
in {
  options.programs.aichat = {
    enable = mkEnableOption "aichat";

    package = mkOption {
      type = types.package;
      default = pkgs.aichat;
      defaultText = literalExpression "pkgs.aichat";
      description = "The aichat package to use.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration options for aichat.";
      example = literalExpression ''
        {
          model = "claude";
          light_theme = false;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."aichat/config.yaml".text =
      lib.generators.toYAML {} cfg.settings;
  };
}
