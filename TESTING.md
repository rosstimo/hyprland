# Lua branch testing

This branch is ready for its first live Hyprland test. The Lua entrypoint is
`hyprland.lua`; the legacy `.conf` files are retained only as a rollback path.

## Inventory result

| Area | Decision |
| --- | --- |
| Hyprland entrypoint, monitors, input, appearance, rules, and binds | Ported to Lua |
| `hypridle.conf`, `hyprlock.conf`, and `hyprsunset.conf` | Kept in their native config formats and removed Omarchy dependencies |
| Legacy Hyprland and binding `.conf` files | Kept temporarily for the first rollback |
| `bindings.conf~` | Deleted as an obsolete backup |
| Keybinding menu | Renamed and made independent of Omarchy |
| Terminal CWD, idle, nightlight, power, screenshot, and recording commands | Replaced with local scripts |
| Omarchy theme/background switching and Omarchy menu | Omitted because they depend on Omarchy's managed assets |

## Before switching

1. Make sure the config repository is clean and back up any uncommitted local
   changes.
2. Confirm `hyprctl version` reports Hyprland 0.55 or newer.
3. Keep a TTY available. The current monitor layout is hardware-specific and
   names `eDP-1`, `DP-5`, `DP-6`, and `DP-7`.

The core session expects Hyprland ecosystem packages plus `ghostty`,
`librewolf`, `thunar`, `waybar`, `walker`, `mako`, `hypridle`, `hyprlock`,
`hyprsunset`, `jq`, `brightnessctl`, `playerctl`, and PipeWire's `wpctl`.
Capture shortcuts additionally use `grim`, `slurp`, `wl-copy`, and
`wf-recorder`. `localsend`, `hyprpicker`, `swaybg`, and a polkit agent are
optional unless their corresponding feature is used.

## Switch and reload

From `~/.config/hypr`:

```sh
git switch lua
hyprctl reload full-reset
hyprctl configerrors
```

`full-reset` is important for the first switch between the old Hyprlang config
and Lua. An empty `hyprctl configerrors` result is the first success condition.

Then inspect what Hyprland registered:

```sh
hyprctl monitors
hyprctl devices
hyprctl binds
hyprctl clients
```

## Live checklist

- Confirm all four displays have the expected positions, scales, and modes.
- Confirm keyboard layout, Compose on Caps Lock, touchpad scrolling, and focus.
- Open Ghostty, LibreWolf, a file dialog, picture-in-picture, and Steam if
  installed. Check float, size, fullscreen, opacity, and idle rules.
- Test workspace switching and moving, the special workspace, directional
  focus, mouse move/resize, fullscreen, maximize, close, and transparency.
- Test volume, media, brightness, app launcher, keybinding menu, notification
  controls, nightlight, idle toggle, lock screen, and the power menu.
- Test region, window, and output screenshots. Test recording without audio
  first, then with audio. Press the same recording shortcut again to stop.
- Suspend once and confirm the screen locks, displays wake, and brightness is
  restored.

## Roll back

If the Lua config prevents a usable graphical session, switch to a TTY and run:

```sh
cd ~/.config/hypr
git switch omarchy
```

Then restart the Hyprland session. If Hyprland is still reachable, switching
back can instead be followed by `hyprctl reload full-reset`.

## Current references

- https://wiki.hypr.land/Configuring/Start/
- https://wiki.hypr.land/Configuring/Basics/Binds/
- https://wiki.hypr.land/Configuring/Basics/Dispatchers/
- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/
- https://wiki.hypr.land/Hypr-Ecosystem/hypridle/
- https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/
- https://wiki.hypr.land/Hypr-Ecosystem/hyprsunset/
