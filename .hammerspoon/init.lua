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

-- Track when we auto-stopped (nil = not auto-stopped)
local autoStoppedAt = nil
local maxLockSeconds = 1 * 60 * 60 -- 1 hours

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
