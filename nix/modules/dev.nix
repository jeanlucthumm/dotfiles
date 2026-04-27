# Development tools
{
  flake.modules.darwin.dev = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      qemu
    ];
  };
}
