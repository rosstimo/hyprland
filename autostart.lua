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

  -- Use our own wallpaper link when present. During migration, the helper can
  -- still read Omarchy's current background link so the existing wallpaper is
  -- preserved without making Omarchy part of the permanent configuration.
  hl.exec_cmd('bash "$HOME/.config/hypr/scripts/wallpaper"')

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
