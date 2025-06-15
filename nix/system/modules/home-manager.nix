# Common system level home manager config.
# This is NOT config for modules within home manager.
# See (home/ for that)
{inputs, ...}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [inputs.agenix.homeManagerModules.default];
  };
}
