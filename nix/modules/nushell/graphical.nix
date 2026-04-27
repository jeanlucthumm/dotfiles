# Nushell — graphical contribution
{
  flake.modules.homeManager.graphical = {...}: {
    programs.nushell = {
      # Enables kitty's new key handling protocol in nushell
      settings.use_kitty_protocol = true;
      shellAliases.nv = "neovide --frame transparent --fork";
    };
  };
}
