# Launches the normal Zen Browser -- same profile, same logins -- but with the
# remote-debugging endpoints the firefox-devtools MCP server attaches to (it
# runs with `--connectExisting`). Driving the real signed-in profile is the
# entire point: a throwaway profile would offer nothing over the Chrome path.
#
# Two endpoints are needed, and they are enabled differently:
#   - Marionette (127.0.0.1:2828) -- the attach channel. Can be turned on with
#     the `marionette.enabled` pref or MOZ_MARIONETTE=1.
#   - WebDriver BiDi (127.0.0.1:9222) -- what the tool calls actually ride on.
#     Without it the MCP server connects but every call fails with
#     "missing webSocketUrl capability".
#
# BiDi has no pref and no env-var equivalent (the Zen binary only ships
# MOZ_MARIONETTE and a lone `remote.log.level` pref), so it can only come from
# the `--remote-debugging-port` command line flag. Raycast, the Dock and
# Spotlight all launch the .app bundle directly and never pass argv, hence this
# wrapper bundle in ~/Applications. Use it instead of the plain Zen entry.
{jlib, ...}: {
  flake.modules.homeManager.graphical = jlib.mkHomeManager {
    darwin = {
      pkgs,
      lib,
      ...
    }: let
      zenApp = "/Applications/Zen Browser.app";
      appName = "Zen Browser (MCP)";
      bidiPort = "9222";

      # Absolute paths throughout: LaunchServices starts this with a bare PATH.
      launcher = pkgs.writeShellScript "zen-mcp" ''
        zen="${zenApp}"
        port="${bidiPort}"

        # No --profile/--new-instance: this is the default profile, with all
        # logins and tabs intact. Only the two debug flags are added.
        #
        # They take effect on a COLD start only. If Zen is already up,
        # `open --args` silently focuses the running instance and drops them,
        # so say so rather than appearing to succeed.
        if /usr/bin/pgrep -f "$zen/Contents/MacOS/zen" >/dev/null 2>&1; then
          if ! /usr/bin/nc -z -w 1 127.0.0.1 "$port" >/dev/null 2>&1; then
            /usr/bin/osascript -e 'display alert "Zen is already running without remote debugging" message "Quit Zen completely, then launch Zen Browser (MCP) again to let the firefox-devtools MCP server attach." as warning' >/dev/null 2>&1
          fi
          exec /usr/bin/open -a "$zen"
        fi

        exec /usr/bin/open -a "$zen" --args \
          --marionette --remote-debugging-port "$port"
      '';

      bundle = pkgs.runCommand "zen-mcp-app" {} ''
        app="$out/${appName}.app"
        mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

        cp ${launcher} "$app/Contents/MacOS/zen-mcp"
        chmod +x "$app/Contents/MacOS/zen-mcp"

        cat > "$app/Contents/Info.plist" <<'PLIST'
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>CFBundleExecutable</key><string>zen-mcp</string>
          <key>CFBundleIdentifier</key><string>com.jeanluc.zen-mcp</string>
          <key>CFBundleName</key><string>Zen Browser (MCP)</string>
          <key>CFBundleDisplayName</key><string>Zen Browser (MCP)</string>
          <key>CFBundleIconFile</key><string>zen.icns</string>
          <key>CFBundlePackageType</key><string>APPL</string>
          <key>CFBundleShortVersionString</key><string>1.0</string>
        </dict>
        </plist>
        PLIST
      '';
    in {
      # Materialised as real files rather than a store symlink: Raycast and
      # LaunchServices index symlinked .app bundles unreliably.
      home.activation.zenMcpApp = lib.hm.dag.entryAfter ["writeBoundary"] ''
        target="$HOME/Applications/${appName}.app"

        $DRY_RUN_CMD /bin/mkdir -p "$HOME/Applications"
        $DRY_RUN_CMD /bin/rm -rf "$target"
        $DRY_RUN_CMD /bin/cp -R "${bundle}/${appName}.app" "$target"
        $DRY_RUN_CMD /bin/chmod -R u+w "$target"

        # Borrow Zen's own icon so it looks native in Raycast.
        if [ -f "${zenApp}/Contents/Resources/firefox.icns" ]; then
          $DRY_RUN_CMD /bin/cp "${zenApp}/Contents/Resources/firefox.icns" \
            "$target/Contents/Resources/zen.icns"
        fi
      '';
    };
  };
}
