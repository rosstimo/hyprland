-- Change the default Omarchy look'n'feel

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general

-- Variables
local activeColorA = "rgba(33ccffee)" -- 33ccffee
local activeColorB = "rgba(00ff99ee)" -- 00ff99ee
local inactiveColor = "rgba(595959aa)" -- 595959aa
local activeBorderColor = {
  colors = { activeColorA, activeColorB },
  angle = 45,
}
local inactiveBorderColor = inactiveColor

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,

    border_size = 0,

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#variable-types for info about colors
    col = {
      active_border = activeBorderColor,
      inactive_border = inactiveBorderColor,
    },

    -- Set to true enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border = false,

    -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
    allow_tearing = false,

    layout = "dwindle",
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
  decoration = {
    rounding = 0,

    shadow = {
      enabled = true,
      range = 20,
      render_power = 3, -- int 1-4
      scale = 0.99, -- float 0.0 1.0
      color = activeColorA, -- rgba(ffffff88), rgba(1a1a1aee)
      color_inactive = inactiveColor, -- rgba(00000055)
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
    blur = {
      enabled = true,
      size = 3,
      passes = 3,
    },

    dim_inactive = false,
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#group
  group = {
    col = {
      border_active = activeBorderColor,
      border_inactive = inactiveBorderColor,
      -- border_locked_active = -1,
      -- border_locked_inactive = -1,
    },

    groupbar = {
      font_size = 12,
      font_family = "monospace",
      font_weight_active = "ultraheavy",
      font_weight_inactive = "normal",

      indicator_height = 0,
      indicator_gap = 5,
      height = 22,
      gaps_in = 5,
      gaps_out = 0,

      text_color = "rgb(ffffff)",
      text_color_inactive = "rgba(ffffff90)",
      col = {
        active = "rgba(00000040)",
        inactive = "rgba(00000020)",
      },

      gradients = true,
      gradient_rounding = 0,
      gradient_round_only_edges = false,
    },
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
  animations = {
    enabled = true, -- yes, please :)
  },
})

-- Default animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/ for more
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
  dwindle = {
    -- pseudotile = true, -- Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = true, -- You probably want this
    force_split = 2, -- Always split on the right
  },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
  master = {
    new_status = "master",
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#misc
hl.config({
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
    anr_missed_pings = 3,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#cursor
hl.config({
  cursor = {
    hide_on_key_press = true,
  },
})
