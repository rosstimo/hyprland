-- Window and layer rules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- These rules preserve the useful application behavior that the legacy
-- configuration inherited from Omarchy. Omarchy-only application classes and
-- its screensaver rules were intentionally left behind.

local function rule(name, match, effects)
  effects.name = name
  effects.match = match
  hl.window_rule(effects)
end

-- Ignore maximize requests from applications and give ordinary windows the
-- default opacity tag. Application rules below remove the tag where needed.
rule("suppress-app-maximize", { class = ".*" }, { suppress_event = "maximize" })
rule("tag-default-opacity", { class = ".*" }, { tag = "+default-opacity" })

-- Fix some dragging issues with XWayland by preventing focus on empty helper
-- windows. This is the Lua equivalent of the inherited default rule.
rule("ignore-empty-xwayland-window", {
  class = "^$",
  title = "^$",
  xwayland = true,
  float = true,
  fullscreen = false,
  pin = false,
}, { no_focus = true })

-- Password managers: hide them from screen sharing and float them.
rule("protect-1password", { class = "^1[Pp]assword$" }, {
  no_screen_share = true,
  tag = "+floating-window",
})
rule("protect-bitwarden", { class = "^Bitwarden$" }, {
  no_screen_share = true,
  tag = "+floating-window",
})

-- Bitwarden Chrome Extension
rule("protect-bitwarden-extension", {
  class = "^chrome-nngceckbapebfimnlniiiahkandclblb-Default$",
}, {
  no_screen_share = true,
  tag = "+floating-window",
})

-- Browser types
rule("tag-chromium-browsers", {
  class = "^((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)$",
}, { tag = "+chromium-based-browser" })
rule("tag-firefox-browsers", {
  class = "^([fF]irefox|zen|librewolf)$",
}, { tag = "+firefox-based-browser" })
rule("exclude-chromium-from-default-opacity", {
  tag = "chromium-based-browser",
}, { tag = "-default-opacity" })
rule("exclude-firefox-from-default-opacity", {
  tag = "firefox-based-browser",
}, { tag = "-default-opacity" })

-- Video apps: remove the Chromium browser tag so browser opacity is not
-- applied to app-mode YouTube and Zoom windows.
rule("exclude-video-webapps-from-browser-opacity", {
  class = "^(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)$",
}, {
  tag = "-chromium-based-browser",
  opacity = "1 1",
})

-- Force Chromium-based browsers into a tile to deal with the --app bug.
rule("tile-chromium-browsers", { tag = "chromium-based-browser" }, { tile = true })

-- Only a subtle opacity change, but not for the video sites above.
rule("chromium-browser-opacity", {
  tag = "chromium-based-browser",
}, { opacity = "1.0 0.97" })
rule("firefox-browser-opacity", {
  tag = "firefox-based-browser",
}, { opacity = "1.0 0.97" })

-- Hide the screen-sharing notification bar. Its Hide button is broken on
-- Wayland, and the special workspace keeps it out of the working area.
rule("hide-browser-screen-share-bar", {
  title = ".*is sharing.*",
}, { workspace = "special silent" })

-- Disable mouse focus for JetBrains IDEs.
rule("jetbrains-focus", { class = "^jetbrains-.*$" }, { no_follow_mouse = true })

-- Float LocalSend and the fzf file picker used for sharing.
rule("float-file-share", { class = "^(Share|localsend)$" }, {
  float = true,
  center = true,
})
rule("size-localsend", { class = "^localsend$" }, { size = { 1100, 700 } })

-- Picture-in-picture overlays
rule("tag-picture-in-picture", {
  title = "Picture.?in.?[Pp]icture",
}, { tag = "+pip" })
rule("style-picture-in-picture", { tag = "pip" }, {
  tag = "-default-opacity",
  float = true,
  pin = true,
  size = { 600, 338 },
  keep_aspect_ratio = true,
  border_size = 0,
  opacity = "1 1",
  move = { "monitor_w-window_w-40", "monitor_h*0.04" },
})

-- Virtual machines and games should remain fully opaque.
rule("qemu-opacity", { class = "^qemu$" }, {
  tag = "-default-opacity",
  opacity = "1 1",
})
rule("retroarch", { class = "^com.libretro.RetroArch$" }, {
  fullscreen = true,
  tag = "-default-opacity",
  opacity = "1 1",
  idle_inhibit = "fullscreen",
})

-- Float Steam and preserve its dialog sizes.
rule("float-steam", { class = "^steam$" }, { float = true })
rule("steam-main-window", { class = "^steam$", title = "^Steam$" }, {
  center = true,
  size = { 1100, 700 },
})
rule("steam-friends-list", { class = "^steam$", title = "^Friends List$" }, {
  size = { 460, 800 },
})
rule("steam-opacity-and-idle", { class = "^steam.*$" }, {
  tag = "-default-opacity",
  opacity = "1 1",
  idle_inhibit = "fullscreen",
})

-- Game streaming
rule("geforce-now", { class = "^GeForceNOW$" }, { idle_inhibit = "fullscreen" })
rule("moonlight", { class = "^com.moonlight_stream.Moonlight$" }, {
  fullscreen = true,
  idle_inhibit = "fullscreen",
})

-- Floating windows
rule("float-tagged-windows", { tag = "floating-window" }, {
  float = true,
  center = true,
  size = { 875, 600 },
})
rule("tag-common-floating-windows", {
  class = "^(org.codeberg.dnkl.foot|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|About|TUI.float|imv|mpv)$",
}, { tag = "+floating-window" })
rule("tag-file-dialogs", {
  class = "^(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)$",
  title = "^(Open.*Files?|Open [Ff]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to (open|save).*|[Cc]hoose.*)$",
}, { tag = "+floating-window" })
rule("float-calculator", { class = "^org.gnome.Calculator$" }, { float = true })

-- No transparency on media windows
rule("opaque-media-windows", {
  class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
}, {
  tag = "-default-opacity",
  opacity = "1 1",
})

-- Popped windows and explicitly no-idle windows
rule("round-popped-windows", { tag = "pop" }, { rounding = 8 })
rule("inhibit-idle-by-tag", { tag = "noidle" }, { idle_inhibit = "always" })

-- Prevent Telegram from stealing focus on new messages.
rule("telegram-focus", {
  class = "^org.telegram.desktop$",
}, { focus_on_activate = false })

-- Float Typora print dialog.
rule("typora-print", { class = "^Typora$", title = "^Print$" }, {
  float = true,
  center = true,
})

-- Define terminal tag to style terminals uniformly.
rule("tag-terminals", {
  class = "^(Alacritty|kitty|com.mitchellh.ghostty|foot)$",
}, {
  tag = "+terminal",
})
rule("terminal-opacity", { tag = "terminal" }, {
  tag = "-default-opacity",
  opacity = "0.97 0.9",
})

-- Webcam overlay for screen recording
rule("webcam-overlay", { title = "^WebcamOverlay$" }, {
  float = true,
  pin = true,
  no_initial_focus = true,
  no_dim = true,
  move = { "monitor_w-window_w-40", "monitor_h-window_h-40" },
})

-- Apply the ordinary-window opacity after application exclusions.
rule("default-window-opacity", { tag = "default-opacity" }, {
  opacity = "0.97 0.9",
})

-- Application-specific layer animations
hl.layer_rule({
  name = "no-anim-for-selection",
  match = { namespace = "^selection$" },
  no_anim = true,
})
hl.layer_rule({
  name = "no-anim-for-walker",
  match = { namespace = "^walker$" },
  no_anim = true,
})

-- BEGIN hypr-window-rule-builder: librewolf-bitwarden
-- Late-title handler generated by hypr-window-rule-builder: librewolf-bitwarden
hl.on("window.title", function(w)
  if w ~= nil
      and w.class == "librewolf"
      and w.title == "Extension: (Bitwarden Password Manager) - Bitwarden — LibreWolf" then
    hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))
    hl.dispatch(hl.dsp.window.resize({ x = 375, y = 500, window = w }))
    hl.dispatch(hl.dsp.window.center({ window = w }))
  end
end)
-- END hypr-window-rule-builder: librewolf-bitwarden

-- BEGIN hypr-window-rule-builder: librewolf-library
rule("librewolf-library", {
  class = "^librewolf$",
  title = "^Library$",
}, {
  float = true,
  size = { 850, 500 },
  center = true,
})
-- END hypr-window-rule-builder: librewolf-library

-- BEGIN hypr-window-rule-builder: files
rule("files", {
  class = "^org\\.gnome\\.Nautilus$",
}, {
  float = true,
  center = true,
  size = { 962, 588 },
})
-- END hypr-window-rule-builder: files
