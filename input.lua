-- Effective input settings from input.conf plus the useful Omarchy defaults
-- that were previously inherited through default/hyprland/input.conf.

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "compose:caps",
    kb_rules = "",
    repeat_rate = 40,
    repeat_delay = 600,
    numlock_by_default = false,
    follow_mouse = 0,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
      scroll_factor = 0.4,
    },
  },
  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})
