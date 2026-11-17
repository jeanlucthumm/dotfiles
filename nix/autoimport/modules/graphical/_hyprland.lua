-- Hyprland binds, submaps and autostart.
-- Appended to the generated hyprland.lua, after the settings in hyprland.nix.

local mod = "SUPER"

hl.on("hyprland.start", function()
  hl.exec_cmd('kitty --detach --title="scratchpad" --override initial_window_width=235c --override initial_window_height=83c')
end)

-- Software launching
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("nautilus"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("zen-beta"))
hl.bind(mod .. " + X", hl.dsp.exec_cmd("qutebrowser"))
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("wofi --show drun"))

-- Hyprland control
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + mouse:277", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }))
hl.bind(mod .. " + SHIFT + I", hl.dsp.workspace.swap_monitors({ monitor1 = "0", monitor2 = "1" }))
hl.bind(mod .. " + I", hl.dsp.group.next())
hl.bind(mod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mod .. " + E", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Software control
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("fish ~/.config/hypr/screencap.fish"))
hl.bind(mod .. " + BACKSLASH", hl.dsp.exec_cmd("makoctl dismiss"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("timew stop; pidof hyprlock || hyprlock"))

-- Media control
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"))

-- TODO don't generate, just explicitly list the nums
-- workspaces
-- binds mod + [shift +] {1..9, 0} to [move to] workspace {1..10}
for ws = 1, 10 do
  local key = ws % 10
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = ws }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws }))
end

-- Move focus with vim directions
-- Swap windows with SHIFT + vim directions
-- Move windows with SHIFT + arrows
for _, d in ipairs({
  { key = "H", arrow = "LEFT", direction = "left" },
  { key = "L", arrow = "RIGHT", direction = "right" },
  { key = "K", arrow = "UP", direction = "up" },
  { key = "J", arrow = "DOWN", direction = "down" },
}) do
  hl.bind(mod .. " + " .. d.key, hl.dsp.focus({ direction = d.direction }))
  hl.bind(mod .. " + SHIFT + " .. d.key, hl.dsp.window.swap({ direction = d.direction }))
  hl.bind(mod .. " + SHIFT + " .. d.arrow, hl.dsp.window.move({ direction = d.direction }))
end

-- Mouse bindings
-- Move/resize windows with mod + LMB/RMB and dragging
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Submaps. A second argument of "reset" returns to the default submap after
-- any bind in the submap fires.

-- Resize
hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  local inc = 20
  local repeating = { repeating = true }
  hl.bind("L", hl.dsp.window.resize({ x = inc, y = 0, relative = true }), repeating)
  hl.bind("H", hl.dsp.window.resize({ x = -inc, y = 0, relative = true }), repeating)
  hl.bind("K", hl.dsp.window.resize({ x = 0, y = -inc, relative = true }), repeating)
  hl.bind("J", hl.dsp.window.resize({ x = 0, y = inc, relative = true }), repeating)
  hl.bind("RETURN", hl.dsp.submap("reset"))
  hl.bind("ESCAPE", hl.dsp.submap("reset"))
end)

-- Power
hl.bind(mod .. " + SHIFT + T", hl.dsp.submap("power"))
hl.define_submap("power", "reset", function()
  hl.bind("S", hl.dsp.exec_cmd("systemctl suspend"))
  hl.bind("P", hl.dsp.exec_cmd("systemctl poweroff"))
  hl.bind("R", hl.dsp.exec_cmd("systemctl reboot"))
end)

-- Master-Layout
hl.bind(mod .. " + M", hl.dsp.submap("master"))
hl.define_submap("master", "reset", function()
  hl.bind("RETURN", hl.dsp.submap("reset"))
  hl.bind(mod .. " + S", hl.dsp.layout("swapwithmaster"))
end)

-- Special workspace
hl.bind(mod .. " + S", hl.dsp.submap("special"))
hl.define_submap("special", "reset", function()
  hl.bind("RETURN", hl.dsp.submap("reset"))
  hl.bind(mod .. " + R", hl.dsp.workspace.toggle_special())
end)
