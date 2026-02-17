{
  config,
  pkgs,
  ...
}: {
  packages = with pkgs; [
    buf
  ];

  dotenv.enable = true;

  languages.go.enable = true;
}
