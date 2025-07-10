# Foundation settings for Darwin.
{config, ...}: {
  programs = {
    nushell.configFile.text = ''
      def nrs []: [nothing -> nothing] {
          nh darwin switch
      }

      def nra []: [nothing -> nothing] {
          nh darwin -u
      }
    '';
  };

  home = {
    # Extra stuff to add to $PATH
    sessionPath = [
      # homebrew puts all its stuff in this directory instead
      # of /usr/bin or otherwise
      "/opt/homebrew/bin"
      # Any Dart dev requires this in path
      "${config.home.homeDirectory}/.pub-cache/bin"
    ];
  };
}
