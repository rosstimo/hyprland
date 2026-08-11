-- Extra env variables
-- hl.env("MY_GLOBAL_ENV", "setting")

-- Environment inherited from the legacy Omarchy configuration, without its
-- theme and update machinery.

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")

hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

local home = os.getenv("HOME")
if home then
  hl.env("XCOMPOSEFILE", home .. "/.XCompose")
end

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})
