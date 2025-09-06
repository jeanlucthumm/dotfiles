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
    # Use go-fmt-fix custom hook for auto-formatting
    go-fmt-fix = {
      enable = true;
      name = "go-fmt-fix";
      entry = "${pkgs.go}/bin/gofmt -w -s";
      files = "\\.go$";
      pass_filenames = true;
    };
  };
}