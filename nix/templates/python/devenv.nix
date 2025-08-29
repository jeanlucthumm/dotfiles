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

  git-hooks.hooks = {
    ruff.enable = true;
    ruff-format.enable = true;
  };
}

