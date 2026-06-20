fp: {
  perSystem = {pkgs, ...}: {
    packages = {
      mcp-opennutrition = pkgs.callPackage ./_derivations/mcp-opennutrition.nix {};
      mcp-language-server = pkgs.callPackage ./_derivations/mcp-language-server.nix {};
      graphiti-mcp-server = pkgs.callPackage ./_derivations/graphiti-mcp-server.nix {
        inherit (fp.inputs) uv2nix pyproject-nix pyproject-build-systems;
      };
      reddit-mcp-server = pkgs.callPackage ./_derivations/reddit-mcp-server.nix {};
      mcp-flutter = pkgs.callPackage ./_derivations/mcp-flutter.nix {};
      notify = pkgs.callPackage ./_derivations/notify.nix {};
      # TODO don't think this is used anymore
      notion-cli = pkgs.callPackage ./_derivations/notion-cli.nix {};
    };
  };
}
