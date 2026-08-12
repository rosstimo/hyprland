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

  -- Waypaper remembers the selected backend, monitor assignments, and
  -- wallpapers. With the awww backend it also starts awww-daemon as needed.
  -- See https://github.com/anufrievroman/waypaper
  start_if_available("waypaper", "waypaper --restore")

  -- Prefer Hyprland's native agent, then try common locations used by Arch,
  -- Fedora, and Debian-family packages.
  hl.exec_cmd(
    "if command -v hyprpolkitagent >/dev/null 2>&1; then "
      .. "exec hyprpolkitagent; "
      .. "fi; "
      .. "for agent in "
      .. "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 "
      .. "/usr/libexec/polkit-gnome-authentication-agent-1; do "
      .. '[ -x "$agent" ] && exec "$agent"; '
      .. "done"
  )
end)
