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

-- Push-to-talk dictation with Whisper
-- Hold Cmd+Shift+P to record, release to transcribe and paste
local dictLog = hs.logger.new("dictation", "info")
local dictPid = nil
local dictFile = "/tmp/dictation.wav"
local ffmpeg = "/etc/profiles/per-user/jeanluc/bin/ffmpeg"

local function startRecording()
    dictLog.i("Starting recording")
    local task = hs.task.new(ffmpeg, nil, {
        "-f", "avfoundation", "-i", ":default", "-y", dictFile
    })
    task:start()
    dictPid = task:pid()
end

local function stopAndTranscribe()
    if dictPid then
        os.execute("kill -INT " .. dictPid)
        dictPid = nil

        -- Wait for file to finalize, then transcribe via daemon
        hs.timer.doAfter(0.1, function()
            local text, status = hs.execute("echo '" .. dictFile .. "' | nc -U /tmp/whisper.sock")
            if status and text and text ~= "" then
                text = text:gsub("^%s*(.-)%s*$", "%1")
                hs.pasteboard.setContents(text)
                hs.eventtap.keyStroke({"cmd"}, "v")
            else
                dictLog.e("Transcription failed or empty")
            end
        end)
    end
end

hs.hotkey.bind({"cmd", "shift"}, "p", startRecording, stopAndTranscribe)
dictLog.i("Dictation hotkey registered (Cmd+Shift+P)")
