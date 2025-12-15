-- Hammerspoon configuration
--
-- Automatically stops timewarrior tracking on screen lock or system sleep,
-- and continues tracking on unlock/wake. Only continues if WE stopped the
-- timer (not if user manually stopped it before locking).
--
-- Logs available in Hammerspoon Console (menu bar → Console)
--
-- Requires: Hammerspoon (brew install hammerspoon)
-- Timewarrior automatic stop/continue on sleep/lock
local caffeine = hs.caffeinate.watcher
local log = hs.logger.new("timew", "info")
local timew = "/etc/profiles/per-user/jeanluc/bin/timew"

-- Track if we auto-stopped (only continue our own stops)
local autoStopped = false

local function caffeineCallback(event)
    if event == caffeine.systemWillSleep or event == caffeine.screensDidLock then
        local reason = event == caffeine.systemWillSleep and "system sleep" or "screen lock"
        local output = hs.execute(timew .. " get dom.active", true)
        if output and output:match("^1") then
            log.i("Stopping timewarrior: " .. reason)
            hs.execute(timew .. " stop", true)
            autoStopped = true
        else
            log.i("No active tracking to stop (" .. reason .. ")")
        end
    elseif event == caffeine.systemDidWake or event == caffeine.screensDidUnlock then
        local reason = event == caffeine.systemDidWake and "system wake" or "screen unlock"
        if autoStopped then
            log.i("Continuing timewarrior: " .. reason)
            hs.execute(timew .. " continue", true)
            autoStopped = false
        else
            log.i("Not continuing (wasn't auto-stopped): " .. reason)
        end
    end
end

caffeinateWatcher = caffeine.new(caffeineCallback)
caffeinateWatcher:start()
log.i("Timewarrior watcher started")
