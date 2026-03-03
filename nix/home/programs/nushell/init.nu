def init-python [] {
  try { git init }
  devenv init
  cp -r ~/nix/templates/python/* .
  cp ~/nix/templates/python/.gitignore .
  cp ~/nix/templates/python/.mcp.json .
}
