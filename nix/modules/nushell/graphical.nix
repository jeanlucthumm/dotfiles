# Nushell — graphical contribution
{
  flake.modules.homeManager.graphical = {...}: {
    # Enables kitty's new key handling protocol in nushell
    programs.nushell.settings.use_kitty_protocol = true;
  };
}
