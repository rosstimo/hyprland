-- Extra autostart processes
-- Add hl.exec_cmd("uwsm app -- my-service") inside the hyprland.start event.

-- Generic session services inherited from the legacy configuration.
-- Omarchy-specific first-run, update, power-profile, monitor-watch, and hook
-- commands are intentionally omitted.

local function start_if_available(program, command)
  hl.exec_cmd("command -v " .. program .. " >/dev/null 2>&1 && " .. (command or program))
end

hl.on("hyprland.start", function()
  -- Keep systemd and D-Bus activation environments aligned with Hyprland.
  start_if_available("systemctl", "systemctl --user import-environment $(env | cut -d= -f 1)")
  start_if_available("dbus-update-activation-environment", "dbus-update-activation-environment --systemd --all")

  start_if_available("hypridle")
  start_if_available("mako")
  start_if_available("waybar")
  start_if_available("fcitx5", "fcitx5 --disable notificationitem")

  -- A wallpaper symlink or file can be added later without changing this
  -- module. Until it exists, swaybg is not started.
  start_if_available(
    "swaybg",
    '[ -e "$HOME/.config/hypr/wallpaper" ] && swaybg -i "$HOME/.config/hypr/wallpaper" -m fill'
  )

  -- Common locations used by Arch, Fedora, and Debian-family packages.
  hl.exec_cmd(
    "for agent in "
      .. "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 "
      .. "/usr/libexec/polkit-gnome-authentication-agent-1; do "
      .. '[ -x "$agent" ] && exec "$agent"; '
      .. "done"
  )
end)
