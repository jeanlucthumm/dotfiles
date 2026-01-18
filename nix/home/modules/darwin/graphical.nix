# Darwin specific GUI settings
{config, pkgs, ...}: {
  imports = [
    ../../programs/hammerspoon.nix
  ];

  # These are darwin specific because NixOS relies on the WM for splits.
  programs = {
    hammerspoon = {
      enable = true;
      extraConfig = ''
        -- Timewarrior automatic stop/continue on sleep/lock
        local caffeine = hs.caffeinate.watcher
        local log = hs.logger.new("timew", "info")
        local timew = "${pkgs.timewarrior}/bin/timew"

        local autoStoppedAt = nil
        local maxLockSeconds = 1 * 60 * 60 -- 1 hour

        local function caffeineCallback(event)
            if event == caffeine.systemWillSleep or event == caffeine.screensDidLock then
                local reason = event == caffeine.systemWillSleep and "system sleep" or "screen lock"
                local output = hs.execute(timew .. " get dom.active", true)
                if output and output:match("^1") then
                    log.i("Stopping timewarrior: " .. reason)
                    hs.execute(timew .. " stop", true)
                    autoStoppedAt = os.time()
                else
                    log.i("No active tracking to stop (" .. reason .. ")")
                end
            elseif event == caffeine.systemDidWake or event == caffeine.screensDidUnlock then
                local reason = event == caffeine.systemDidWake and "system wake" or "screen unlock"
                if autoStoppedAt then
                    local elapsed = os.time() - autoStoppedAt
                    if elapsed <= maxLockSeconds then
                        log.i(string.format("Continuing timewarrior: %s (locked for %dm)", reason, math.floor(elapsed / 60)))
                        hs.execute(timew .. " continue", true)
                    else
                        log.i(string.format("Not continuing (locked too long: %dh %dm)", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60)))
                    end
                    autoStoppedAt = nil
                else
                    log.i("Not continuing (wasn't auto-stopped): " .. reason)
                end
            end
        end

        caffeinateWatcher = caffeine.new(caffeineCallback)
        caffeinateWatcher:start()
        log.i("Timewarrior watcher started")
      '';
    };
    kitty = {
      settings = {
        macos_option_as_alt = true;
        macos_titlebar_color = "background";
        # macOS GUI apps don't inherit shell PATH, so tell kitty where to find nvim
        exe_search_path = "/etc/profiles/per-user/${config.home.username}/bin";
      };
      keybindings = {
        "cmd+p" = "previous_tab";
        "cmd+n" = "next_tab";
        "cmd+shift+p" = "move_tab_backward";
        "cmd+shift+n" = "move_tab_forward";
        "cmd+k" = "focus_visible_window";
        "cmd+shift+r" = "set_tab_title";
        "cmd+h" = "previous_window";
        "cmd+l" = "next_window";
        "cmd+enter" = "new_window_with_cwd";
      };
    };
    nushell.shellAliases.nv = "neovide --frame transparent --fork";
  };
}
