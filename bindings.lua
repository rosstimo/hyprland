-- KEYBINDINGS
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

-- Bind options replace the old single-letter bind flags:
-- locked: works while an input inhibitor, such as a lock screen, is active.
-- release: triggers on release of a key.
-- click: triggers on release if the pointer stays inside binds.drag_threshold.
-- drag: triggers on release if the pointer moves beyond binds.drag_threshold.
-- long_press: triggers on a long press.
-- repeating: repeats while held.
-- non_consuming: also passes the key or mouse event to the active window.
-- mouse: enables mouse-button window actions.
-- transparent: cannot be shadowed by another bind.
-- ignore_mods: ignores modifiers.
-- description: exposes a readable description through `hyprctl binds`.
-- dont_inhibit: bypasses an application's request to inhibit keybinds.

-- Example volume button that allows press and hold, volume limited to 150%:
-- hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(
--   "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
-- ), { repeating = true })

-- Start wofi on first release and close it on the second:
-- hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("pkill wofi || wofi"), {
--   release = true,
-- })

-- Skip the player on a long press and only skip five seconds on a normal press:
-- hl.bind("SUPER + XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), {
--   long_press = true,
-- })
-- hl.bind("SUPER + XF86AudioNext", hl.dsp.exec_cmd("playerctl position +5"))

-- --- Main modifier ---
local mainMod = "SUPER"
local terminal = "ghostty"
local browser = "librewolf"
local configDir = '$HOME/.config/hypr'

local function described_bind(keys, dispatcher, description, options)
  options = options or {}
  options.description = description
  hl.bind(keys, dispatcher, options)
end

-- --- Window State ---
described_bind(mainMod .. " + SPACE", hl.dsp.window.float(), "Window: Toggle Floating")
-- See https://wiki.hypr.land/Configuring/Basics/Dispatchers/#window-1
described_bind(mainMod .. " + F", hl.dsp.window.fullscreen({
  mode = "fullscreen",
  action = "toggle",
}), "Window: Toggle Full Screen")
described_bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({
  mode = "maximized",
  action = "toggle",
}), "Window: Toggle Maximize")
described_bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen_state({
  internal = -1,
  client = 2,
}), "Window: Toggle Full Screen Client (fake)")
described_bind(mainMod .. " + Q", hl.dsp.window.close({}), "Window: Close Active")

-- --- Focus movement ---
described_bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }), "Window: Focus Left")
described_bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }), "Window: Focus Right")
described_bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }), "Window: Focus Up")
described_bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }), "Window: Focus Down")

-- --- Mouse actions ---
described_bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), "Window: Mouse Move", {
  mouse = true,
})
described_bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Window: Mouse Resize", {
  mouse = true,
})
described_bind(mainMod .. " + BACKSPACE", hl.dsp.window.set_prop({
  prop = "opaque",
  value = "toggle",
}), "Window: Toggle Transparency")

-- --- Workspace switching ---
for workspace = 1, 9 do
  described_bind(mainMod .. " + " .. workspace, hl.dsp.focus({
    workspace = workspace,
  }), "Workspace: Switch to " .. workspace)

  -- --- Move window to workspace ---
  described_bind(mainMod .. " + SHIFT + " .. workspace, hl.dsp.window.move({
    workspace = workspace,
  }), "Workspace: Move Window to " .. workspace)
end

-- --- Special workspace (scratchpad) ---
described_bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), "Workspace: Toggle Special")
described_bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({
  workspace = "special:magic",
}), "Workspace: Move Window to Special")

-- --- Workspace scrolling ---
described_bind(mainMod .. " + mouse_down", hl.dsp.focus({
  workspace = "e+1",
}), "Workspace: Scroll Down")
described_bind(mainMod .. " + mouse_up", hl.dsp.focus({
  workspace = "e-1",
}), "Workspace: Scroll Up")

-- --- Media and volume controls ---
-- Use Nerd Font symbols for special-function-key descriptions.
local media_repeat = { locked = true, repeating = true }
local media_locked = { locked = true }
described_bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(
  "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
), "Media: Volume Up 󰕾", media_repeat)
described_bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(
  "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
), "Media: Volume Down ", { locked = true, repeating = true })
described_bind("XF86AudioMute", hl.dsp.exec_cmd(
  "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
), "Media: Mute 󰖁", { locked = true, repeating = true })
described_bind("XF86AudioMicMute", hl.dsp.exec_cmd(
  "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
), "Media: Mute Microphone 󰖁", { locked = true, repeating = true })
described_bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Media: Next 󰒬", media_locked)
described_bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Media: Pause 󰏤", {
  locked = true,
})
described_bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Media: Play 󰐊", {
  locked = true,
})
described_bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Media: Previous 󰒫", {
  locked = true,
})

-- Application bindings
described_bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(
  terminal .. ' --working-directory="$(' .. configDir .. '/scripts/terminal-cwd)"'
), "App: Terminal")
described_bind(mainMod .. " + E", hl.dsp.exec_cmd(
  "if command -v uwsm >/dev/null 2>&1; then exec uwsm app -- thunar; else exec thunar; fi"
), "App: File manager")
described_bind(mainMod .. " + W", hl.dsp.exec_cmd(browser), "App: Browser")
described_bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(
  browser .. " --private-window"
), "App: Browser (private)")

-- Other app ideas retained from the old configuration:
-- SUPER + M: Spotify
-- SUPER + D: lazydocker in a terminal
-- SUPER + G: Signal
-- SUPER + O: Obsidian
-- SUPER + slash: password manager

-- --- Web apps ---
-- Lua strings do not treat # as a comment, so URLs no longer need ## escaping.
described_bind(mainMod .. " + A", hl.dsp.exec_cmd(
  browser .. " --new-window https://chatgpt.com"
), "App Web: ChatGPT")
described_bind(mainMod .. " + C", hl.dsp.exec_cmd(
  browser .. " --new-window https://calendar.google.com/calendar"
), "App Web: Calendar")
described_bind(mainMod .. " + Y", hl.dsp.exec_cmd(
  browser .. " --new-window https://youtube.com/"
), "App Web: YouTube")
described_bind(mainMod .. " + D", hl.dsp.exec_cmd(
  browser .. " --new-window https://isu.instructure.com/"
), "App Web: Canvas")

-- Tools
described_bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal .. " -e btop"), "Tools: System Monitor")
described_bind("CTRL + ESCAPE", hl.dsp.exec_cmd("pkill -x waybar || waybar"), "Tools: Toggle Waybar", {
  release = true,
})
described_bind(mainMod .. " + CTRL + I", hl.dsp.exec_cmd(
  configDir .. "/scripts/toggle-idle"
), "Tools: Toggle lock on idle")
described_bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(
  "pkill -x hyprpicker || hyprpicker -a"
), "Tools: Color picker")
described_bind("CTRL + " .. mainMod .. " + S", hl.dsp.exec_cmd("localsend"), "Tools: File Share")

-- Notifications
described_bind(mainMod .. " + COMMA", hl.dsp.exec_cmd("makoctl dismiss"), "Notifications: Dismiss Last")
described_bind(mainMod .. " + SHIFT + COMMA", hl.dsp.exec_cmd(
  "makoctl dismiss --all"
), "Notifications: Dismiss All")
described_bind(mainMod .. " + CTRL + COMMA", hl.dsp.exec_cmd(
  "makoctl mode -t do-not-disturb && "
    .. "if makoctl mode | grep -q do-not-disturb; then "
    .. "notify-send 'Silenced notifications'; else notify-send 'Enabled notifications'; fi"
), "Notifications: Toggle Silence")

-- Menu
described_bind("ALT + SPACE", hl.dsp.exec_cmd("walker -p 'Start…'"), "Menu: App Launcher")
described_bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("walker -m Emojis"), "Menu: Emoji Picker")
described_bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(
  configDir .. "/scripts/power-menu"
), "Menu: Power")
described_bind("XF86PowerOff", hl.dsp.exec_cmd(
  configDir .. "/scripts/power-menu"
), "Menu: Power", { locked = true })
described_bind(mainMod .. " + K", hl.dsp.exec_cmd(
  configDir .. "/scripts/menu-keybindings"
), "Menu: Key Bindings")

-- Theme switching was tied to Omarchy's theme store and is intentionally not
-- active here. A wallpaper can be supplied as ~/.config/hypr/wallpaper.

-- Display
described_bind("PRINT", hl.dsp.exec_cmd(
  configDir .. "/scripts/screenshot region"
), "Display: Screenshot of region")
described_bind("SHIFT + PRINT", hl.dsp.exec_cmd(
  configDir .. "/scripts/screenshot window"
), "Display: Screenshot of window")
described_bind("CTRL + PRINT", hl.dsp.exec_cmd(
  configDir .. "/scripts/screenshot output"
), "Display: Screenshot of display")
described_bind("ALT + PRINT", hl.dsp.exec_cmd(
  configDir .. "/scripts/screen-record region"
), "Display: Screen record a region")
described_bind("ALT + SHIFT + PRINT", hl.dsp.exec_cmd(
  configDir .. "/scripts/screen-record region audio"
), "Display: Screen record a region with audio")
described_bind("CTRL + ALT + PRINT", hl.dsp.exec_cmd(
  configDir .. "/scripts/screen-record output"
), "Display: Screen record display")
described_bind("CTRL + ALT + SHIFT + PRINT", hl.dsp.exec_cmd(
  configDir .. "/scripts/screen-record output audio"
), "Display: Screen record display with audio")
described_bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(
  "brightnessctl -e4 -n2 set 5%+"
), "Display: Brightness Up 󰌬", { locked = true, repeating = true })
described_bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(
  "brightnessctl -e4 -n2 set 5%-"
), "Display: Brightness Down 󰌭", { locked = true, repeating = true })
described_bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd(
  configDir .. "/scripts/toggle-nightlight"
), "Display: Toggle nightlight")
