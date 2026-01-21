# Solaar home-manager module
# Declarative configuration for Logitech device button remapping
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.solaar;

  # Convert device config to YAML format
  deviceToYaml = name: device: ''
    - _NAME: ${name}
      _modelId: ${device.modelId}
      _serial: ${device.serial}
      _unitId: ${device.unitId}
      _wpid: ${device.wpid}
      divert-keys: {${concatStringsSep ", " (map (b: "${toString b}: 1") device.divertButtons)}}
  '';

  # Convert rule to YAML format
  ruleToYaml = rule: ''
    ---
    - Key: [${rule.button}, ${rule.state}]
    - KeyPress: [${concatStringsSep ", " rule.keyPress}]
    ...
  '';
in {
  options.programs.solaar = {
    enable = mkEnableOption "Solaar Logitech device manager configuration";

    devices = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          modelId = mkOption {
            type = types.str;
            description = "Device model ID (find via `solaar show`)";
            example = "B03400000000";
          };
          serial = mkOption {
            type = types.str;
            description = "Device serial number";
            example = "EB5ACC14";
          };
          unitId = mkOption {
            type = types.str;
            description = "Device unit ID (usually same as serial)";
            example = "EB5ACC14";
          };
          wpid = mkOption {
            type = types.str;
            description = "Wireless PID";
            example = "B034";
          };
          divertButtons = mkOption {
            type = types.listOf types.int;
            default = [];
            description = "Button CIDs to divert (send HID++ notifications instead of normal input)";
            example = [195]; # 195 = Mouse Gesture Button
          };
        };
      });
      default = {};
      description = "Logitech devices to configure";
    };

    rules = mkOption {
      type = types.listOf (types.submodule {
        options = {
          button = mkOption {
            type = types.str;
            description = "Button name to trigger on";
            example = "Mouse Gesture Button";
          };
          state = mkOption {
            type = types.enum ["pressed" "released"];
            default = "pressed";
            description = "Button state to trigger on";
          };
          keyPress = mkOption {
            type = types.listOf types.str;
            description = "Keys to send when triggered";
            example = ["Super_L" "Shift_L" "F10"];
          };
        };
      });
      default = [];
      description = "Rules mapping diverted buttons to key presses";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "solaar/config.yaml".text = ''
        - 1.1.16
        ${concatStringsSep "\n" (mapAttrsToList deviceToYaml cfg.devices)}
      '';

      "solaar/rules.yaml".text = concatStringsSep "\n" (map ruleToYaml cfg.rules);
    };
  };
}
