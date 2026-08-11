-- Control your input devices
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
--
-- Effective input settings from input.conf plus the useful Omarchy defaults
-- that were previously inherited through default/hyprland/input.conf.

hl.config({
  input = {
    -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
    -- kb_layout = "us,dk,eu",
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "compose:caps", -- ,grp:alts_toggle
    kb_rules = "",

    -- Change speed of keyboard repeat
    repeat_rate = 40,
    repeat_delay = 600,

    -- Start with numlock on by default
    numlock_by_default = false,

    -- Increase sensitity for mouse/trackpack (default: 0)
    -- sensitivity = 0.35,
    sensitivity = 0,

    -- Better control of window focus
    follow_mouse = 0,

    touchpad = {
      -- Use natural (inverse) scrolling
      -- natural_scroll = true,
      natural_scroll = false,

      -- Use two-finger clicks for right-click instead of lower-right corner
      -- clickfinger_behavior = true,

      -- Control the speed of your scrolling
      scroll_factor = 0.4,
    },
  },
  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Scroll nicely in the terminal
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- hl.window_rule({
--   name = "terminal-scroll-touchpad",
--   match = { class = "Alacritty|kitty" },
--   scroll_touchpad = 1.5,
-- })
-- hl.window_rule({
--   name = "ghostty-scroll-touchpad",
--   match = { class = "com.mitchellh.ghostty" },
--   scroll_touchpad = 0.2,
-- })

-- Enable touchpad gestures for changing workspaces
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
