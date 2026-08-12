# Lua branch testing

This branch is ready for live Hyprland testing. The Lua entrypoint is
`hyprland.lua`; the legacy `.conf` files are retained only as a rollback path.

## Inventory result

| Area | Decision |
| --- | --- |
| Hyprland entrypoint, input, appearance, rules, and binds | Ported to Lua |
| Display layout | Owned by `nwg-displays`; its generated `monitors.lua` is loaded through `displays.lua` and ignored by Git |
| Wallpaper | Decoupled from Omarchy; `~/.config/hypr/wallpaper` is preferred, with the old Omarchy background link used only as a migration fallback |
| `hypridle.conf`, `hyprlock.conf`, and `hyprsunset.conf` | Kept in their native config formats and removed Omarchy dependencies |
| Legacy Hyprland and binding `.conf` files | Kept temporarily for the first rollback |
| `bindings.conf~` | Deleted as an obsolete backup |
| Keybinding menu | Renamed and made independent of Omarchy |
| Terminal CWD, idle, nightlight, power, screenshot, recording, and wallpaper commands | Replaced with local scripts |
| Omarchy theme switching and Omarchy menu | Omitted because they depend on Omarchy-managed assets |

## Before switching

1. Make sure the config repository is clean and back up any uncommitted local
   changes.
2. Confirm `hyprctl version` reports Hyprland 0.55 or newer.
3. Make sure `nwg-displays` is installed. On Hyprland 0.55+ it should generate
   `~/.config/hypr/monitors.lua` whenever settings are applied.

If `monitors.lua` does not exist when Hyprland first loads the branch,
`displays.lua` supplies a temporary `preferred` / automatic-position / scale 1
fallback. Open `nwg-displays` and click Apply to replace that fallback with the
real layout.

The core session expects Hyprland ecosystem packages plus `ghostty`,
`librewolf`, `thunar`, `waybar`, `walker`, `mako`, `hypridle`, `hyprlock`,
`hyprsunset`, `jq`, `brightnessctl`, `playerctl`, and PipeWire's `wpctl`.
Capture shortcuts additionally use `grim`, `slurp`, `wl-copy`, and
`wf-recorder`. `localsend` and `hyprpicker` are optional unless their
corresponding feature is used. Wallpaper support needs either `swaybg` or
`hyprpaper`.

## Switch and reload

From `~/.config/hypr`:

```sh
git switch lua
git pull
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

## Display test with nwg-displays

Open `nwg-displays`, verify the layout, resolution, refresh rate, and scale, then
click Apply. It should regenerate both its legacy `monitors.conf` and the Lua
file used by this branch.

Check the generated Lua file and make sure Git ignores it:

```sh
sed -n '1,200p' ~/.config/hypr/monitors.lua
git status --short
```

`monitors.lua` should not appear in `git status`. Change one harmless display
setting in `nwg-displays`, apply it, then change it back and apply again. The
layout should update immediately both times without editing the repository.

## Wallpaper test

Run the wallpaper helper manually once:

```sh
bash ~/.config/hypr/scripts/wallpaper
```

During migration it will use the old Omarchy current-background link if no
Hyprland-owned wallpaper has been selected yet.

To make a wallpaper independent of Omarchy, pass an image once:

```sh
bash ~/.config/hypr/scripts/wallpaper ~/Pictures/example.jpg
```

That creates or updates `~/.config/hypr/wallpaper` as a symlink to the selected
image and applies it immediately. Future Hyprland starts use that link first.

## Live checklist

- Confirm all displays have the positions, scales, modes, and refresh rates set
  in `nwg-displays`.
- Confirm the wallpaper appears after login and survives a Hyprland restart.
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
- https://wiki.hypr.land/Configuring/Basics/Monitors/
- https://wiki.hypr.land/Configuring/Basics/Binds/
- https://wiki.hypr.land/Configuring/Basics/Dispatchers/
- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/
- https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/
- https://wiki.hypr.land/Hypr-Ecosystem/hypridle/
- https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/
- https://wiki.hypr.land/Hypr-Ecosystem/hyprsunset/
- https://github.com/nwg-piotr/nwg-displays#hyprland
