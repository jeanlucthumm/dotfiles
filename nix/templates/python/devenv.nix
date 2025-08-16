{
  config,
  pkgs,
  ...
}: {
  packages = with pkgs; [
    ruff
    pyright
  ];

  env = rec {};

  dotenv.enable = true;

  languages.python = {
    enable = true;
    uv = {
      enable = true;
      sync.enable = true;
    };
    venv.enable = true;
  };
}

