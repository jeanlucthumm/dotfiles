# Darwin-specific agenix/security configuration
# YubiKey decryption requires interactive PIN + touch, so we disable the
# automatic launchd agent and provide `delock` for manual invocation.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Agenix sets ProgramArguments = [ mountingScript ]; home-manager wraps
  # it in the plist but the config value is the unwrapped nix store path.
  mountScript = builtins.head config.launchd.agents.activate-agenix.config.ProgramArguments;
in {
  age.package = pkgs.writeShellScriptBin "age" ''
    export PATH="${lib.makeBinPath [pkgs.age-plugin-yubikey]}:$PATH"
    exec ${pkgs.age}/bin/age "$@"
  '';

  launchd.agents.activate-agenix.config = {
    RunAtLoad = lib.mkForce false;
    KeepAlive = lib.mkForce {};
  };

  home.packages = [
    (pkgs.writeShellScriptBin "delock" ''
      exec ${mountScript}
    '')
  ];
}
