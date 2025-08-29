{
  config,
  pkgs,
  ...
}: {
  packages = with pkgs; [
  ];

  dotenv.enable = true;

  languages.go.enable = true;

  git-hooks.hooks = {
    gofmt.enable = true;
  };
}