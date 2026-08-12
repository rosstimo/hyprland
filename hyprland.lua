-- Hyprland Lua configuration entrypoint.
-- See https://wiki.hypr.land/Configuring/Start/
--
-- The legacy .conf files remain in this branch for the first testing pass and
-- rollback only. They are not sourced by this Lua configuration.

require("envs")
require("autostart")
require("displays")
require("input")
require("looknfeel")
require("windows")
require("bindings")
