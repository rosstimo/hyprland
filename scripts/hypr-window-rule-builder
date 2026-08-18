#!/usr/bin/env python3
'''
hypr-window-rule-builder
Interactive Hyprland Lua window-rule builder.

Designed for Hyprland >= 0.55 Lua configuration.
References:
  https://wiki.hypr.land/Configuring/Basics/Window-Rules/
  https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/

Runtime requirements:
  - python >= 3.10
  - hyprctl
Optional:
  - fzf      nicer selectors
  - wl-copy  copy generated rule to clipboard
'''

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Any, Iterable

VERSION = "0.3.0"

MATCH_FIELDS = (
    "class",
    "title",
    "initial_class",
    "initial_title",
    "tag",
    "xwayland",
    "float",
    "fullscreen",
    "pin",
    "focus",
    "group",
    "modal",
    "workspace",
    "content",
    "xdg_tag",
)

BOOL_MATCH_FIELDS = {"xwayland", "float", "fullscreen", "pin", "focus", "group", "modal"}

EFFECT_MENU = [
    ("capture_state", "Capture current state", "float/tile, geometry, workspace, monitor, fullscreen, pin"),
    ("float", "Float", "float = true"),
    ("tile", "Tile", "tile = true"),
    ("center", "Center", "center = true"),
    ("size_current", "Current size", "size = current width/height"),
    ("move_current", "Current position", "move = current monitor-local x/y"),
    ("workspace_current", "Current workspace", "workspace = current workspace"),
    ("monitor_current", "Current monitor", "monitor = current monitor name"),
    ("fullscreen", "Fullscreen", "fullscreen = true"),
    ("maximize", "Maximize", "maximize = true"),
    ("pin", "Pin", "pin = true"),
    ("pseudo", "Pseudo tile", "pseudo = true"),
    ("persistent_size", "Remember floating size", "persistent_size = true"),
    ("keep_aspect_ratio", "Keep aspect ratio", "keep_aspect_ratio = true"),
    ("opaque", "Force opaque", "opaque = true"),
    ("no_screen_share", "Hide from screen sharing", "no_screen_share = true"),
    ("no_initial_focus", "No initial focus", "no_initial_focus = true"),
    ("focus_on_activate_false", "Block focus-on-activate", "focus_on_activate = false"),
    ("no_follow_mouse", "No follow mouse", "no_follow_mouse = true"),
    ("no_focus", "Never focus", "no_focus = true"),
    ("no_anim", "No animation", "no_anim = true"),
    ("no_blur", "No blur", "no_blur = true"),
    ("no_dim", "No dim", "no_dim = true"),
    ("no_shadow", "No shadow", "no_shadow = true"),
    ("no_shortcuts_inhibit", "Block shortcut inhibition", "no_shortcuts_inhibit = true"),
    ("idle_inhibit", "Idle inhibit...", "none / always / focus / fullscreen"),
    ("opacity", "Opacity...", 'e.g. "1.0 0.9"'),
    ("rounding", "Rounding...", "pixel count"),
    ("border_size", "Border size...", "pixel count"),
    ("tag", "Apply tag...", '"+name", "-name", or "name"'),
    ("workspace_custom", "Workspace...", 'e.g. "3", "special:name silent"'),
    ("monitor_custom", "Monitor...", 'e.g. "eDP-1"'),
    ("size_custom", "Size...", "two Lua values/expressions"),
    ("move_custom", "Position...", "two Lua values/expressions"),
    ("suppress_event", "Suppress event...", "maximize, activate, ..."),
    ("content", "Content type...", "none / photo / video / game"),
    ("custom", "Custom effect...", "arbitrary effect = Lua value"),
]


@dataclass
class LuaRule:
    name: str
    match: dict[str, Any]
    effects: dict[str, Any]
    file: Path
    line: int
    raw: str
    unknown_match: set[str] = field(default_factory=set)


class UserCancelled(Exception):
    """Raised when the user intentionally cancels an interactive step."""


def eprint(*args: Any, **kwargs: Any) -> None:
    print(*args, file=sys.stderr, **kwargs)


def run_json(*args: str) -> Any:
    proc = subprocess.run(
        ["hyprctl", "-j", *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"hyprctl {' '.join(args)} failed")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON from hyprctl {' '.join(args)}: {exc}") from exc


def clear() -> None:
    if sys.stdout.isatty():
        print("\033[2J\033[H", end="")


def terminal_width(default: int = 100) -> int:
    try:
        return shutil.get_terminal_size().columns
    except OSError:
        return default


def truncate(value: Any, width: int) -> str:
    s = str(value or "").replace("\n", " ")
    if len(s) <= width:
        return s
    return s[: max(1, width - 1)] + "…"


def fzf_select(
    entries: list[tuple[str, str]],
    prompt: str,
    *,
    multi: bool = False,
    header: str | None = None,
) -> list[str]:
    if not entries:
        return []

    fzf = shutil.which("fzf")
    if fzf and sys.stdin.isatty() and sys.stdout.isatty():
        rows = [f"{key}\t{display}" for key, display in entries]
        full_header = "Esc cancels" if not header else f"{header}  |  Esc cancels"
        cmd = [
            fzf,
            "--ansi",
            "--delimiter=\t",
            "--with-nth=2..",
            "--layout=reverse",
            "--border",
            "--height=90%",
            f"--prompt={prompt} ",
            f"--header={full_header}",
        ]
        if multi:
            cmd.extend(["--multi", "--bind=space:toggle"])
        proc = subprocess.run(
            cmd,
            input="\n".join(rows) + "\n",
            text=True,
            stdout=subprocess.PIPE,
        )
        if proc.returncode != 0:
            raise UserCancelled
        return [line.split("\t", 1)[0] for line in proc.stdout.splitlines()]

    print()
    print(prompt)
    for i, (_, display) in enumerate(entries, 1):
        print(f"  {i:>2}. {display}")
    if multi:
        raw = input("Choose numbers separated by spaces (blank = none, q = cancel): ").strip()
        if raw.lower() in {"q", "quit", "cancel"}:
            raise UserCancelled
        if not raw:
            return []
        out: list[str] = []
        for token in re.split(r"[\s,]+", raw):
            if token.isdigit() and 1 <= int(token) <= len(entries):
                out.append(entries[int(token) - 1][0])
        return out
    raw = input("Choose number (q = cancel): ").strip()
    if raw.lower() in {"q", "quit", "cancel"} or not raw:
        raise UserCancelled
    if not raw.isdigit() or not (1 <= int(raw) <= len(entries)):
        raise UserCancelled
    return [entries[int(raw) - 1][0]]


def prompt_value(label: str, default: str = "") -> str:
    suffix = f" [{default}]" if default else ""
    value = input(f"{label}{suffix}: ").strip()
    return value if value else default


def prompt_yes_no(label: str, default: bool = False) -> bool:
    hint = "Y/n" if default else "y/N"
    raw = input(f"{label} [{hint}]: ").strip().lower()
    if not raw:
        return default
    return raw in {"y", "yes"}


def lua_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def exact_regex(value: str) -> str:
    # Escape RE2 metacharacters without turning ordinary spaces or hyphens into
    # noisy backslash escapes. This keeps generated title matchers readable.
    escaped = re.sub(r"([\\.^$|?*+(){}\[\]])", r"\\\1", value)
    return "^" + escaped + "$"


def bool_lua(value: bool) -> str:
    return "true" if value else "false"


def client_workspace(client: dict[str, Any]) -> tuple[Any, str]:
    ws = client.get("workspace") or {}
    return ws.get("id", ""), str(ws.get("name", ""))


def client_tags(client: dict[str, Any]) -> list[str]:
    tags = client.get("tags") or []
    if isinstance(tags, str):
        return [tags]
    return [str(t) for t in tags]


def monitor_for_client(client: dict[str, Any], monitors: list[dict[str, Any]]) -> dict[str, Any] | None:
    cid = client.get("monitor")
    for mon in monitors:
# __WRB_ASSEMBLY_GUARD_0_0__
# __WRB_ASSEMBLY_GUARD_0_1__
# __WRB_ASSEMBLY_GUARD_0_2__
# __WRB_ASSEMBLY_GUARD_0_3__
# __WRB_ASSEMBLY_GUARD_0_4__
# __WRB_ASSEMBLY_GUARD_0_5__
# __WRB_ASSEMBLY_GUARD_0_6__
        if mon.get("id") == cid:
            return mon
    for mon in monitors:
        if mon.get("name") == cid:
            return mon
    return None


def window_display(client: dict[str, Any], active_addr: str) -> str:
    ws_id, ws_name = client_workspace(client)
    mark = "*" if client.get("address") == active_addr else " "
    mode = "F" if client.get("floating") else "T"
    try:
        fs_state = int(client.get("fullscreen") or 0)
    except (TypeError, ValueError):
        fs_state = 0
    if fs_state in {1, 3}:
        mode += "M"
    if fs_state in {2, 3}:
        mode += "S"
    if client.get("pinned"):
        mode += "P"
    cls = truncate(client.get("class") or "<no class>", 32)
    title = truncate(client.get("title") or "<no title>", 60)
    ws = ws_name or ws_id
    return f"{mark} ws:{ws!s:<6} {mode:<3} {cls:<32}  {title}"


def choose_client(clients: list[dict[str, Any]], active: dict[str, Any]) -> dict[str, Any] | None:
    active_addr = str(active.get("address") or "")
    ordered = sorted(
        clients,
        key=lambda c: (
            0 if str(c.get("address") or "") == active_addr else 1,
            (c.get("workspace") or {}).get("id", 999999),
            str(c.get("class") or "").lower(),
            str(c.get("title") or "").lower(),
        ),
    )
    entries = [(str(c.get("address")), window_display(c, active_addr)) for c in ordered]
    keys = fzf_select(
        entries,
        "Window>",
        header="* active   F floating   T tiled   M maximized   S fullscreen   P pinned",
    )
    if not keys:
        return None
    key = keys[0]
    return next((c for c in ordered if str(c.get("address")) == key), None)


def print_client(client: dict[str, Any], monitors: list[dict[str, Any]], active_addr: str) -> None:
    ws_id, ws_name = client_workspace(client)
    mon = monitor_for_client(client, monitors)
    at = client.get("at") or ["?", "?"]
    size = client.get("size") or ["?", "?"]
    tags = ", ".join(client_tags(client)) or "(none)"
    print("Selected window")
    print("=" * min(80, terminal_width()))
    print(f"Address       : {client.get('address', '')}")
    print(f"Class         : {client.get('class', '')}")
    print(f"Initial class : {client.get('initialClass', '')}")
    print(f"Title         : {client.get('title', '')}")
    print(f"Initial title : {client.get('initialTitle', '')}")
    print(f"Workspace     : {ws_name or ws_id} (id {ws_id})")
    print(f"Monitor       : {(mon or {}).get('name', client.get('monitor', ''))}")
    print(f"Position      : {at}")
    print(f"Size          : {size}")
    print(f"Floating      : {bool(client.get('floating'))}")
    print(f"Fullscreen    : {client.get('fullscreen', 0)}")
    print(f"Pinned        : {bool(client.get('pinned'))}")
    print(f"XWayland      : {bool(client.get('xwayland'))}")
    if "modal" in client:
        print(f"Modal         : {bool(client.get('modal'))}")
    print(f"Focused       : {str(client.get('address')) == active_addr}")
    print(f"Tags          : {tags}")
    if client.get("xdgTag"):
        print(f"XDG tag       : {client.get('xdgTag')}")


# ---------- Minimal Lua static parser ----------

def _scan_balanced(text: str, start: int, open_char: str, close_char: str) -> int | None:
    if start >= len(text) or text[start] != open_char:
        return None
    depth = 0
    i = start
    quote: str | None = None
    long_string = False
    while i < len(text):
        ch = text[i]

        if long_string:
            if text.startswith("]]", i):
                long_string = False
                i += 2
                continue
            i += 1
            continue

        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue

        if text.startswith("--[[", i):
            end = text.find("]]", i + 4)
            if end < 0:
                return len(text)
            i = end + 2
            continue
        if text.startswith("--", i):
            end = text.find("\n", i + 2)
            if end < 0:
                return len(text)
            i = end + 1
            continue
        if text.startswith("[[", i):
            long_string = True
            i += 2
            continue
        if ch in {"'", '"'}:
            quote = ch
            i += 1
            continue
        if ch == open_char:
            depth += 1
        elif ch == close_char:
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return None


def _split_top_level(text: str, delimiter: str = ",") -> list[str]:
    parts: list[str] = []
    start = 0
    stack: list[str] = []
    quote: str | None = None
    i = 0
    pairs = {")": "(", "}": "{", "]": "["}
    while i < len(text):
        ch = text[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in {"'", '"'}:
            quote = ch
            i += 1
            continue
        if ch in "({[":
            stack.append(ch)
        elif ch in ")}]":
            if stack and stack[-1] == pairs[ch]:
                stack.pop()
        elif ch == delimiter and not stack:
            parts.append(text[start:i].strip())
            start = i + 1
        i += 1
    tail = text[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def _find_top_level_equals(text: str) -> int:
    stack: list[str] = []
    quote: str | None = None
    i = 0
    pairs = {")": "(", "}": "{", "]": "["}
    while i < len(text):
        ch = text[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in {"'", '"'}:
            quote = ch
        elif ch in "({[":
            stack.append(ch)
        elif ch in ")}]":
            if stack and stack[-1] == pairs[ch]:
                stack.pop()
        elif ch == "=" and not stack:
            return i
        i += 1
    return -1


def _unquote_lua(value: str) -> str | None:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        body = value[1:-1]
        body = body.replace(r"\\", "\\")
        if value[0] == '"':
            body = body.replace(r"\"", '"')
        else:
            body = body.replace(r"\'", "'")
        return body
    return None


def _parse_lua_value(value: str) -> Any:
    value = value.strip()
    quoted = _unquote_lua(value)
    if quoted is not None:
        return quoted
    if value == "true":
        return True
    if value == "false":
        return False
    if value == "nil":
        return None
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    if re.fullmatch(r"-?(?:\d+\.\d*|\d*\.\d+)", value):
        return float(value)
    if value.startswith("{") and value.endswith("}"):
        return _parse_lua_table(value)
    return {"__lua__": value}


def _parse_lua_table(table: str) -> dict[str, Any] | list[Any]:
    table = table.strip()
    if not (table.startswith("{") and table.endswith("}")):
        return {"__lua__": table}
    inner = table[1:-1]
    fields = _split_top_level(inner)
    keyed: dict[str, Any] = {}
    positional: list[Any] = []
    for field in fields:
        eq = _find_top_level_equals(field)
        if eq >= 0:
            key = field[:eq].strip()
            val = field[eq + 1 :].strip()
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
                keyed[key] = _parse_lua_value(val)
            else:
                keyed[key] = {"__lua__": val}
        elif field:
            positional.append(_parse_lua_value(field))
    if keyed and positional:
        keyed["__positional__"] = positional
        return keyed
    if keyed:
# __WRB_ASSEMBLY_GUARD_1_0__
# __WRB_ASSEMBLY_GUARD_1_1__
# __WRB_ASSEMBLY_GUARD_1_2__
# __WRB_ASSEMBLY_GUARD_1_3__
# __WRB_ASSEMBLY_GUARD_1_4__
# __WRB_ASSEMBLY_GUARD_1_5__
# __WRB_ASSEMBLY_GUARD_1_6__
        return keyed
    return positional


def extract_rules_from_text(text: str, path: Path) -> list[LuaRule]:
    rules: list[LuaRule] = []
    pattern = re.compile(r"(?<![\w.])(hl\.window_rule|rule)\s*\(")
    for match in pattern.finditer(text):
        call_name = match.group(1)
        open_paren = text.find("(", match.start(), match.end() + 1)
        if open_paren < 0:
            continue
        end = _scan_balanced(text, open_paren, "(", ")")
        if end is None:
            continue
        raw = text[match.start() : end]
        args_text = text[open_paren + 1 : end - 1]
        args = _split_top_level(args_text)
        line = text.count("\n", 0, match.start()) + 1

        name = f"{path.name}:{line}"
        match_table: dict[str, Any] = {}
        effects: dict[str, Any] = {}
        unknown: set[str] = set()

        if call_name == "rule" and len(args) >= 3:
            # Only analyze literal helper calls. This skips the helper function
            # signature itself and arbitrary computed match/effect tables.
            if not args[1].lstrip().startswith("{") or not args[2].lstrip().startswith("{"):
                continue
            parsed_name = _unquote_lua(args[0])
            if parsed_name:
                name = parsed_name
            parsed_match = _parse_lua_value(args[1])
            parsed_effects = _parse_lua_value(args[2])
            if isinstance(parsed_match, dict):
                match_table = parsed_match
            else:
                unknown.add("<match-table>")
            if isinstance(parsed_effects, dict):
                effects = parsed_effects
        elif call_name == "hl.window_rule" and args:
            # Computed tables are valid Lua, but cannot be resolved safely by
            # this static analyzer.
            if not args[0].lstrip().startswith("{"):
                continue
            parsed = _parse_lua_value(args[0])
            if isinstance(parsed, dict):
                parsed_name = parsed.pop("name", None)
                if isinstance(parsed_name, str):
                    name = parsed_name
                parsed_match = parsed.pop("match", None)
                if isinstance(parsed_match, dict):
                    match_table = parsed_match
                else:
                    unknown.add("<match-table>")
                effects = parsed
        if match_table or unknown:
            rules.append(
                LuaRule(
                    name=name,
                    match=match_table,
                    effects=effects,
                    file=path,
                    line=line,
                    raw=raw,
                    unknown_match=unknown,
                )
            )
    return rules


def scan_lua_rules(config_dir: Path) -> list[LuaRule]:
    rules: list[LuaRule] = []
    if not config_dir.exists():
        return rules
    for path in sorted(config_dir.rglob("*.lua")):
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        rules.extend(extract_rules_from_text(text, path))
    return rules


def regex_matches(pattern: str, value: str) -> bool | None:
    negate = False
    if pattern.startswith("negative:"):
        negate = True
        pattern = pattern[len("negative:") :]
    try:
        result = re.search(pattern, value) is not None
    except re.error:
        return None
    return not result if negate else result


def _normalize_tag(tag: str) -> str:
    return tag[:-1] if tag.endswith("*") else tag


def eval_match_field(
    key: str,
    expected: Any,
    client: dict[str, Any],
    active_addr: str,
) -> bool | None:
    if isinstance(expected, dict) and "__lua__" in expected:
        return None

    if key == "class":
        return regex_matches(str(expected), str(client.get("class") or ""))
    if key == "title":
        return regex_matches(str(expected), str(client.get("title") or ""))
    if key == "initial_class":
        return regex_matches(str(expected), str(client.get("initialClass") or ""))
    if key == "initial_title":
        return regex_matches(str(expected), str(client.get("initialTitle") or ""))
    if key == "xdg_tag":
        return regex_matches(str(expected), str(client.get("xdgTag") or ""))
    if key == "tag":
        wanted = _normalize_tag(str(expected).lstrip("+-"))
        tags = {_normalize_tag(t) for t in client_tags(client)}
        return wanted in tags
    if key == "xwayland":
        return bool(client.get("xwayland")) is bool(expected)
    if key == "float":
        return bool(client.get("floating")) is bool(expected)
    if key == "fullscreen":
        return bool(int(client.get("fullscreen") or 0)) is bool(expected)
    if key == "pin":
        return bool(client.get("pinned")) is bool(expected)
    if key == "focus":
        return (str(client.get("address")) == active_addr) is bool(expected)
    if key == "group":
        grouped = client.get("grouped") or []
        return bool(grouped) is bool(expected)
    if key == "fullscreen_state_internal":
        return int(client.get("fullscreen") or 0) == int(expected)
    if key == "fullscreen_state_client":
        return int(client.get("fullscreenClient") or 0) == int(expected)
    if key == "workspace":
        ws_id, ws_name = client_workspace(client)
        exp = str(expected)
        if exp.startswith("name:"):
            return ws_name == exp[5:]
        if exp.isdigit() or (exp.startswith("-") and exp[1:].isdigit()):
            return str(ws_id) == exp
        return None
    if key == "content":
        current = client.get("content") or client.get("contentType")
        if current is None:
            return None
        return str(current) == str(expected)
    if key == "modal":
        if "modal" not in client:
            return None
        return bool(client.get("modal")) is bool(expected)
    return None


def matching_rules(
    rules: Iterable[LuaRule],
    client: dict[str, Any],
    active_addr: str,
) -> list[tuple[str, LuaRule, list[str]]]:
    results: list[tuple[str, LuaRule, list[str]]] = []
    for rule in rules:
        unknown = list(rule.unknown_match)
        failed = False
        for key, expected in rule.match.items():
            state = eval_match_field(key, expected, client, active_addr)
            if state is False:
                failed = True
                break
            if state is None:
                unknown.append(key)
        if failed:
            continue
        status = "MATCH" if not unknown else "POSSIBLE"
        results.append((status, rule, sorted(set(unknown))))
    return results


def summarize_value(value: Any) -> str:
    if isinstance(value, dict) and "__lua__" in value:
        return str(value["__lua__"])
    if isinstance(value, dict):
        return "{ " + ", ".join(f"{k}={summarize_value(v)}" for k, v in value.items()) + " }"
    if isinstance(value, list):
        return "{ " + ", ".join(summarize_value(v) for v in value) + " }"
    if isinstance(value, str):
        return repr(value)
    return str(value)


def print_matching_rules(matches: list[tuple[str, LuaRule, list[str]]], config_dir: Path) -> None:
    print()
    print("Existing rules affecting this window")
    print("=" * min(80, terminal_width()))
    if not matches:
        print("(No literal Lua rules matched.)")
        return
    for status, rule, unknown in matches:
        try:
            rel = rule.file.relative_to(config_dir)
        except ValueError:
            rel = rule.file
        effects = ", ".join(f"{k}={summarize_value(v)}" for k, v in rule.effects.items())
        if not effects:
            effects = "(effects could not be parsed)"
        suffix = f"  unknown match fields: {', '.join(unknown)}" if unknown else ""
        print(f"[{status:<8}] {rule.name}  {rel}:{rule.line}")
        print(f"           {effects}{suffix}")


# ---------- Rule builder ----------

# __WRB_ASSEMBLY_GUARD_2_0__
# __WRB_ASSEMBLY_GUARD_2_1__
# __WRB_ASSEMBLY_GUARD_2_2__
# __WRB_ASSEMBLY_GUARD_2_3__
# __WRB_ASSEMBLY_GUARD_2_4__
# __WRB_ASSEMBLY_GUARD_2_5__
# __WRB_ASSEMBLY_GUARD_2_6__
def matcher_default(field: str, client: dict[str, Any], active_addr: str) -> str:
    if field == "class":
        return exact_regex(str(client.get("class") or ""))
    if field == "title":
        return exact_regex(str(client.get("title") or ""))
    if field == "initial_class":
        return exact_regex(str(client.get("initialClass") or ""))
    if field == "initial_title":
        return exact_regex(str(client.get("initialTitle") or ""))
    if field == "xdg_tag":
        return exact_regex(str(client.get("xdgTag") or ""))
    if field == "tag":
        tags = client_tags(client)
        return _normalize_tag(tags[0]) if tags else ""
    if field == "xwayland":
        return bool_lua(bool(client.get("xwayland")))
    if field == "float":
        return bool_lua(bool(client.get("floating")))
    if field == "fullscreen":
        return bool_lua(bool(int(client.get("fullscreen") or 0)))
    if field == "pin":
        return bool_lua(bool(client.get("pinned")))
    if field == "focus":
        return bool_lua(str(client.get("address")) == active_addr)
    if field == "group":
        return bool_lua(bool(client.get("grouped") or []))
    if field == "modal":
        return bool_lua(bool(client.get("modal")))
    if field == "workspace":
        ws_id, ws_name = client_workspace(client)
        return str(ws_id if ws_id != "" else f"name:{ws_name}")
    if field == "content":
        return str(client.get("content") or client.get("contentType") or "")
    return ""


def matcher_entries(client: dict[str, Any], active_addr: str) -> list[tuple[str, str]]:
    entries = []
    for field in MATCH_FIELDS:
        default = matcher_default(field, client, active_addr)
        if field in {"class", "title", "initial_class", "initial_title", "xdg_tag"}:
            raw_field = {
                "class": "class",
                "title": "title",
                "initial_class": "initialClass",
                "initial_title": "initialTitle",
                "xdg_tag": "xdgTag",
            }[field]
            raw = str(client.get(raw_field) or "")
            display_default = truncate(raw, 60) or "(empty)"
        else:
            display_default = default or "(not available)"
        entries.append((field, f"{field:<15} current: {display_default}"))
    return entries


def _edit_matchers(
    fields: list[str],
    client: dict[str, Any],
    active_addr: str,
) -> dict[str, str]:
    out: dict[str, str] = {}
    print()
    print("Matcher values")
    print("Press Enter to keep each suggested value.")
    for field in fields:
        default = matcher_default(field, client, active_addr)
        if field in BOOL_MATCH_FIELDS:
            value = prompt_value(field, default or "false").lower()
            if value not in {"true", "false"}:
                print(f"  Invalid boolean for {field}; using {default or 'false'}.")
                value = default or "false"
        else:
            value = prompt_value(field, default)
        if value:
            out[field] = value
    return out


def build_match(client: dict[str, Any], active_addr: str) -> dict[str, str]:
    cls = str(client.get("class") or "")
    title = str(client.get("title") or "")
    initial_cls = str(client.get("initialClass") or "")
    initial_title = str(client.get("initialTitle") or "")

    profiles: list[tuple[str, str]] = []
    if cls:
        profiles.append((
            "app",
            f"All {truncate(cls, 36)} windows  |  match class only",
        ))
    if initial_cls and initial_title:
        profiles.append((
            "initial",
            f"Launch identity  |  initial class + initial title: {truncate(initial_title, 38)}",
        ))
    if cls and title:
        changed = "  (title changed since launch)" if title != initial_title else ""
        profiles.append((
            "window",
            f"Current identity  |  class + current title: {truncate(title, 42)}{changed}",
        ))
    profiles.append(("custom", "Custom match fields  |  advanced"))

    print()
    print("How should this rule identify the window?")
    selected = fzf_select(
        profiles,
        "Identify>",
        header="Launch identity is safer for startup behavior. Current title is more precise but may change after creation.",
    )[0]

    if selected == "app":
        fields = ["class"]
    elif selected == "window":
        fields = ["class", "title"]
    elif selected == "initial":
        fields = ["initial_class", "initial_title"]
    else:
        print()
        print("Select match fields. Space toggles items; Enter accepts.")
        fields = fzf_select(
            matcher_entries(client, active_addr),
            "Match>",
            multi=True,
            header="Select one or more fields. Enter with nothing selected is not allowed.",
        )
        if not fields:
            print("A rule needs at least one match field.")
            raise UserCancelled

    out = {field: matcher_default(field, client, active_addr) for field in fields}
    out = {field: value for field, value in out.items() if value != ""}

    print()
    print("Match preview")
    print("=" * min(80, terminal_width()))
    for field, value in out.items():
        print(f"{field:<15} {value}")
    if prompt_yes_no("Edit these matcher values?", False):
        out = _edit_matchers(fields, client, active_addr)

    if not out:
        print("No usable matcher values were produced.")
        raise UserCancelled
    return out


def mon_local_position(client: dict[str, Any], monitors: list[dict[str, Any]]) -> tuple[int, int] | None:
    at = client.get("at")
    if not isinstance(at, list) or len(at) < 2:
        return None
    mon = monitor_for_client(client, monitors)
    try:
        x = int(at[0])
        y = int(at[1])
        if mon:
            x -= int(mon.get("x") or 0)
            y -= int(mon.get("y") or 0)
        return x, y
    except (TypeError, ValueError):
        return None


def client_fullscreen_flags(client: dict[str, Any]) -> tuple[bool, bool]:
    """Return (fullscreen, maximized) from Hyprland's internal fullscreen state."""
    try:
        state = int(client.get("fullscreen") or 0)
    except (TypeError, ValueError):
        state = 0
    return state in {2, 3}, state in {1, 3}


def live_boolean_state(key: str, client: dict[str, Any]) -> bool | None:
    fullscreen, maximized = client_fullscreen_flags(client)
    mapping: dict[str, bool | None] = {
        "fullscreen": fullscreen,
        "maximize": maximized,
        "pin": bool(client.get("pinned")),
        "pseudo": bool(client.get("pseudo")) if "pseudo" in client else None,
        "focus_on_activate": None,
        "persistent_size": None,
        "keep_aspect_ratio": None,
        "opaque": None,
        "no_screen_share": None,
        "no_initial_focus": None,
        "no_follow_mouse": None,
        "no_focus": None,
        "no_anim": None,
        "no_blur": None,
        "no_dim": None,
        "no_shadow": None,
        "no_shortcuts_inhibit": None,
    }
    return mapping.get(key)


BOOLEAN_EFFECTS: list[tuple[str, str, str]] = [
    ("fullscreen", "Fullscreen", "open fullscreen"),
    ("maximize", "Maximize", "open maximized"),
    ("pin", "Pin", "show on all workspaces; floating only"),
    ("pseudo", "Pseudo tile", "use pseudotiling"),
    ("persistent_size", "Remember floating size", "allow size persistence"),
    ("keep_aspect_ratio", "Keep aspect ratio", "preserve aspect ratio while resizing"),
    ("opaque", "Force opaque", "disable transparency"),
    ("no_screen_share", "Hide from screen sharing", "block capture of this window"),
    ("no_initial_focus", "No initial focus", "do not focus when opened"),
    ("focus_on_activate", "Focus on activate", "allow app activation to focus the window"),
    ("no_follow_mouse", "No follow mouse", "ignore follow-mouse focus"),
    ("no_focus", "Never focus", "prevent focus"),
    ("no_anim", "No animation", "disable window animations"),
# __WRB_ASSEMBLY_GUARD_3_0__
# __WRB_ASSEMBLY_GUARD_3_1__
# __WRB_ASSEMBLY_GUARD_3_2__
# __WRB_ASSEMBLY_GUARD_3_3__
# __WRB_ASSEMBLY_GUARD_3_4__
# __WRB_ASSEMBLY_GUARD_3_5__
# __WRB_ASSEMBLY_GUARD_3_6__
    ("no_blur", "No blur", "disable blur"),
    ("no_dim", "No dim", "disable dimming"),
    ("no_shadow", "No shadow", "disable shadow"),
    ("no_shortcuts_inhibit", "Block shortcut inhibition", "ignore app shortcut-inhibit requests"),
]


def choose_enum(label: str, values: list[str], default: str = "") -> str:
    entries = [(v, v) for v in values]
    selected = fzf_select(entries, f"{label}>")
    return selected[0] if selected else default


def parse_vec2_prompt(label: str, default: tuple[Any, Any] | None = None) -> str:
    d1 = str(default[0]) if default else ""
    d2 = str(default[1]) if default else ""
    x = prompt_value(f"{label} X / width", d1)
    y = prompt_value(f"{label} Y / height", d2)

    def item(v: str) -> str:
        if re.fullmatch(r"-?(?:\d+(?:\.\d*)?|\.\d+)", v):
            return v
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            return v
        return lua_quote(v)

    return f"{{ {item(x)}, {item(y)} }}"


def _vec2_summary(value: str) -> str:
    return value.replace("{", "").replace("}", "").strip()


def _effect_value_summary(key: str, effects: dict[str, str], client: dict[str, Any]) -> str:
    if key == "mode":
        if effects.get("float") == "true":
            return "float"
        if effects.get("tile") == "true":
            return "tile"
        return "unchanged"
    if key == "size":
        return _vec2_summary(effects["size"]) if "size" in effects else "unchanged"
    if key == "position":
        if effects.get("center") == "true":
            return "center"
        if "move" in effects:
            return _vec2_summary(effects["move"])
        return "unchanged"
    if key in effects:
        return effects[key]
    state = live_boolean_state(key, client)
    if state is None:
        return "unchanged"
    return f"unchanged (live: {str(state).lower()})"


def _edit_boolean_effect(effects: dict[str, str], client: dict[str, Any], key: str, label: str) -> None:
    live = live_boolean_state(key, client)
    live_text = "unknown" if live is None else str(live).lower()
    current = effects.get(key, "unchanged")
    choice = fzf_select(
        [
            ("unchanged", f"Leave unchanged  |  current rule: {current}; live window: {live_text}"),
            ("true", "Set true"),
            ("false", "Set false"),
        ],
        f"{label}>",
        header="Selecting a property edits its value. Nothing is enabled just by highlighting it.",
    )[0]
    if choice == "unchanged":
        effects.pop(key, None)
    else:
        effects[key] = choice


def _edit_mode(effects: dict[str, str], client: dict[str, Any]) -> None:
    current_mode = "floating" if client.get("floating") else "tiled"
    choice = fzf_select(
        [
            ("unchanged", f"Leave unchanged  |  live window: {current_mode}"),
            ("float", "Float this window"),
            ("tile", "Tile this window"),
        ],
        "Mode>",
        header="Choose one. Float and tile are mutually exclusive.",
    )[0]
    effects.pop("float", None)
    effects.pop("tile", None)
    if choice == "float":
        effects["float"] = "true"
    elif choice == "tile":
        effects["tile"] = "true"
        effects.pop("size", None)
        effects.pop("move", None)
        effects.pop("center", None)


def _edit_size(effects: dict[str, str], client: dict[str, Any]) -> None:
    size = client.get("size") or []
    entries = [("unchanged", "Leave size unchanged")]
    if isinstance(size, list) and len(size) >= 2:
        entries.append(("current", f"Use live size ({size[0]} x {size[1]})"))
    entries.append(("custom", "Set a custom size"))
    choice = fzf_select(entries, "Size>")[0]
    if choice == "unchanged":
        effects.pop("size", None)
    elif choice == "current" and len(size) >= 2:
        effects["size"] = f"{{ {int(size[0])}, {int(size[1])} }}"
    else:
        default = (size[0], size[1]) if len(size) >= 2 else None
        effects["size"] = parse_vec2_prompt("Size", default)


def _edit_position(effects: dict[str, str], client: dict[str, Any], monitors: list[dict[str, Any]]) -> None:
    pos = mon_local_position(client, monitors)
    entries = [
        ("unchanged", "Leave position unchanged"),
        ("center", "Center the window"),
    ]
    if pos:
        entries.append(("current", f"Use live position ({pos[0]}, {pos[1]} monitor-local)"))
    entries.append(("custom", "Set a custom position"))
    choice = fzf_select(entries, "Position>")[0]
    effects.pop("move", None)
    effects.pop("center", None)
    if choice == "center":
        effects["center"] = "true"
    elif choice == "current" and pos:
        effects["move"] = f"{{ {pos[0]}, {pos[1]} }}"
    elif choice == "custom":
        effects["move"] = parse_vec2_prompt("Position", pos)


def _edit_workspace(effects: dict[str, str], client: dict[str, Any]) -> None:
    ws_id, ws_name = client_workspace(client)
    live = str(ws_name or ws_id or "")
    choice = fzf_select(
        [
            ("unchanged", f"Leave workspace unchanged  |  live: {live or 'unknown'}"),
            ("current", f"Use live workspace ({live})"),
            ("custom", "Set a workspace"),
        ],
        "Workspace>",
    )[0]
    if choice == "unchanged":
        effects.pop("workspace", None)
    elif choice == "current":
        if ws_id != "":
            effects["workspace"] = lua_quote(str(ws_id))
        elif ws_name:
            effects["workspace"] = lua_quote(f"name:{ws_name}")
    else:
        effects["workspace"] = lua_quote(prompt_value("Workspace", live or "1"))


def _edit_monitor(effects: dict[str, str], client: dict[str, Any], monitors: list[dict[str, Any]]) -> None:
    mon = monitor_for_client(client, monitors)
    live = str((mon or {}).get("name") or client.get("monitor") or "")
    choice = fzf_select(
        [
            ("unchanged", f"Leave monitor unchanged  |  live: {live or 'unknown'}"),
            ("current", f"Use live monitor ({live})"),
            ("custom", "Set a monitor"),
        ],
        "Monitor>",
    )[0]
    if choice == "unchanged":
        effects.pop("monitor", None)
    elif choice == "current" and live:
        effects["monitor"] = lua_quote(live)
    else:
        effects["monitor"] = lua_quote(prompt_value("Monitor", live))


def _edit_other_effect(effects: dict[str, str], client: dict[str, Any], monitors: list[dict[str, Any]], key: str) -> None:
    if key == "workspace":
        _edit_workspace(effects, client)
    elif key == "monitor":
        _edit_monitor(effects, client, monitors)
    elif key == "idle_inhibit":
        value = choose_enum("Idle inhibit", ["unchanged", "none", "always", "focus", "fullscreen"], "unchanged")
        if value == "unchanged":
            effects.pop("idle_inhibit", None)
        else:
            effects["idle_inhibit"] = lua_quote(value)
    elif key == "opacity":
        if prompt_yes_no("Leave opacity unchanged?", "opacity" not in effects):
            effects.pop("opacity", None)
        else:
            effects["opacity"] = lua_quote(prompt_value("Opacity", "1.0 0.9"))
    elif key == "rounding":
        if prompt_yes_no("Leave rounding unchanged?", "rounding" not in effects):
            effects.pop("rounding", None)
        else:
            effects["rounding"] = prompt_value("Rounding pixels", "8")
    elif key == "border_size":
        if prompt_yes_no("Leave border size unchanged?", "border_size" not in effects):
            effects.pop("border_size", None)
        else:
            effects["border_size"] = prompt_value("Border size", "0")
    elif key == "tag":
        if prompt_yes_no("Leave tags unchanged?", "tag" not in effects):
            effects.pop("tag", None)
        else:
            effects["tag"] = lua_quote(prompt_value("Tag", "+custom"))
    elif key == "suppress_event":
        if prompt_yes_no("Do not suppress events?", "suppress_event" not in effects):
# __WRB_ASSEMBLY_GUARD_4_0__
# __WRB_ASSEMBLY_GUARD_4_1__
# __WRB_ASSEMBLY_GUARD_4_2__
# __WRB_ASSEMBLY_GUARD_4_3__
# __WRB_ASSEMBLY_GUARD_4_4__
# __WRB_ASSEMBLY_GUARD_4_5__
# __WRB_ASSEMBLY_GUARD_4_6__
            effects.pop("suppress_event", None)
        else:
            effects["suppress_event"] = lua_quote(prompt_value("Suppressed events", "maximize"))
    elif key == "content":
        value = choose_enum("Content", ["unchanged", "none", "photo", "video", "game"], "unchanged")
        if value == "unchanged":
            effects.pop("content", None)
        else:
            effects["content"] = lua_quote(value)
    elif key == "custom":
        effect_name = prompt_value("Effect name")
        if effect_name:
            lua_value = prompt_value("Lua value", effects.get(effect_name, "true"))
            effects[effect_name] = lua_value


def _property_entries(effects: dict[str, str], client: dict[str, Any]) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = [
        ("done", "Done editing properties"),
        ("mode", f"Window mode                 {_effect_value_summary('mode', effects, client)}"),
        ("size", f"Size                        {_effect_value_summary('size', effects, client)}"),
        ("position", f"Position                    {_effect_value_summary('position', effects, client)}"),
    ]
    for key, label, help_text in BOOLEAN_EFFECTS:
        value = _effect_value_summary(key, effects, client)
        entries.append((f"bool:{key}", f"{label:<27} {value:<28} {help_text}"))
    ws = effects.get("workspace", "unchanged")
    mon = effects.get("monitor", "unchanged")
    entries.extend([
        ("other:workspace", f"{'Workspace':<27} {ws}"),
        ("other:monitor", f"{'Monitor':<27} {mon}"),
        ("other:idle_inhibit", f"{'Idle inhibit':<27} {effects.get('idle_inhibit', 'unchanged')}"),
        ("other:opacity", f"{'Opacity':<27} {effects.get('opacity', 'unchanged')}"),
        ("other:rounding", f"{'Rounding':<27} {effects.get('rounding', 'unchanged')}"),
        ("other:border_size", f"{'Border size':<27} {effects.get('border_size', 'unchanged')}"),
        ("other:tag", f"{'Tag':<27} {effects.get('tag', 'unchanged')}"),
        ("other:suppress_event", f"{'Suppress event':<27} {effects.get('suppress_event', 'unchanged')}"),
        ("other:content", f"{'Content type':<27} {effects.get('content', 'unchanged')}"),
        ("other:custom", "Custom effect..."),
    ])
    return entries


def edit_effects_draft(
    client: dict[str, Any],
    monitors: list[dict[str, Any]],
    effects: dict[str, str] | None = None,
) -> dict[str, str]:
    effects = dict(effects or {})
    while True:
        print()
        print("Rule properties")
        selected = fzf_select(
            _property_entries(effects, client),
            "Property>",
            header="Select a property to edit it. Values shown as 'unchanged' will not appear in the rule.",
        )[0]
        if selected == "done":
            break
        if selected == "mode":
            _edit_mode(effects, client)
        elif selected == "size":
            _edit_size(effects, client)
        elif selected == "position":
            _edit_position(effects, client, monitors)
        elif selected.startswith("bool:"):
            key = selected.split(":", 1)[1]
            label = next(label for item_key, label, _ in BOOLEAN_EFFECTS if item_key == key)
            _edit_boolean_effect(effects, client, key, label)
        elif selected.startswith("other:"):
            _edit_other_effect(effects, client, monitors, selected.split(":", 1)[1])

    # Defensive conflict cleanup.
    if effects.get("float") == "true":
        effects.pop("tile", None)
    if effects.get("tile") == "true":
        effects.pop("float", None)
        effects.pop("size", None)
        effects.pop("move", None)
        effects.pop("center", None)
    if effects.get("center") == "true":
        effects.pop("move", None)
    return effects


def capture_window_state(client: dict[str, Any], monitors: list[dict[str, Any]]) -> dict[str, str]:
    """Capture the selected live window as an editable rule-property draft."""
    effects: dict[str, str] = {}
    if client.get("floating"):
        effects["float"] = "true"
        size = client.get("size") or []
        pos = mon_local_position(client, monitors)
        if isinstance(size, list) and len(size) >= 2:
            effects["size"] = f"{{ {int(size[0])}, {int(size[1])} }}"
        if pos:
            effects["move"] = f"{{ {pos[0]}, {pos[1]} }}"
    else:
        effects["tile"] = "true"

    fullscreen, maximized = client_fullscreen_flags(client)
    effects["fullscreen"] = bool_lua(fullscreen)
    effects["maximize"] = bool_lua(maximized)
    effects["pin"] = bool_lua(bool(client.get("pinned")))
    if "pseudo" in client:
        effects["pseudo"] = bool_lua(bool(client.get("pseudo")))

    ws_id, ws_name = client_workspace(client)
    if ws_id != "":
        effects["workspace"] = lua_quote(str(ws_id))
    elif ws_name:
        effects["workspace"] = lua_quote(f"name:{ws_name}")

    mon = monitor_for_client(client, monitors)
    if mon and mon.get("name"):
        effects["monitor"] = lua_quote(str(mon["name"]))
    return effects


def refresh_selected_window(address: str) -> tuple[dict[str, Any], list[dict[str, Any]], str]:
    clients = run_json("clients")
    monitors = run_json("monitors")
    active = run_json("activewindow")
    if not isinstance(clients, list):
        raise RuntimeError("Hyprland did not return a client list while capturing the window.")
    refreshed = next((c for c in clients if str(c.get("address") or "") == address), None)
    if not refreshed:
        raise RuntimeError("The selected window closed before its state could be captured.")
    if not isinstance(monitors, list):
        monitors = []
    active_addr = str(active.get("address") or "") if isinstance(active, dict) else ""
    return refreshed, monitors, active_addr


def manually_adjust_and_capture(
    client: dict[str, Any],
    monitors: list[dict[str, Any]],
) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, str]]:
    print()
    print("Manual window capture")
    print("=" * min(80, terminal_width()))
    print("Leave this terminal open. Adjust the selected window however you want:")
    print("float/tile it, move it, resize it, maximize/fullscreen it, or pin/unpin it.")
    print("When it looks right, return to this terminal and press Enter.")
    input("Press Enter to capture the adjusted window...")

    address = str(client.get("address") or "")
    refreshed, refreshed_monitors, active_addr = refresh_selected_window(address)
    print()
    print("Captured live state")
    print_client(refreshed, refreshed_monitors, active_addr)
    effects = capture_window_state(refreshed, refreshed_monitors)
    print()
    print("The capture is only a draft. You can change or remove any captured property next.")
    return refreshed, refreshed_monitors, effects


def build_effects(
    client: dict[str, Any],
    monitors: list[dict[str, Any]],
) -> tuple[dict[str, str], dict[str, Any], list[dict[str, Any]]]:
    print()
    print("Window behavior")
    workflow = fzf_select(
        [
            ("adjust", "Adjust the live window manually, then capture it"),
            ("current", "Capture the window exactly as it is now"),
            ("manual", "Build the rule properties manually"),
        ],
        "Behavior>",
        header="Captured state becomes an editable draft before any rule is generated.",
    )[0]

    draft: dict[str, str] = {}
    working_client = client
    working_monitors = monitors
    if workflow == "adjust":
        working_client, working_monitors, draft = manually_adjust_and_capture(client, monitors)
    elif workflow == "current":
        draft = capture_window_state(client, monitors)
        print("Captured current state as a draft. Review it in the property editor.")

    effects = edit_effects_draft(working_client, working_monitors, draft)
    if not effects:
        print("No behavior changes are currently in the rule.")
    return effects, working_client, working_monitors


# __WRB_ASSEMBLY_GUARD_5_0__
# __WRB_ASSEMBLY_GUARD_5_1__
# __WRB_ASSEMBLY_GUARD_5_2__
# __WRB_ASSEMBLY_GUARD_5_3__
# __WRB_ASSEMBLY_GUARD_5_4__
# __WRB_ASSEMBLY_GUARD_5_5__
# __WRB_ASSEMBLY_GUARD_5_6__
def warn_about_static_title_match(
    matchers: dict[str, str],
    effects: dict[str, str],
    client: dict[str, Any],
) -> None:
    static_effects = {
        "float", "tile", "fullscreen", "maximize", "move", "size", "center", "pseudo",
        "monitor", "workspace", "no_initial_focus", "pin", "persistent_size",
        "keep_aspect_ratio", "suppress_event", "content",
    }
    if not (static_effects & effects.keys()):
        return
    if "title" not in matchers:
        return
    current_title = str(client.get("title") or "")
    initial_title = str(client.get("initialTitle") or "")
    if not current_title or current_title == initial_title:
        return
    print()
    print("WARNING: current title differs from initial title.")
    print("This rule contains startup/static effects such as float/size/position.")
    print("Hyprland evaluates those when the window is created, so a matcher based only on")
    print("a title that appears later may not apply those effects. Review the match fields if needed.")

def sanitize_rule_name(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    return value or "window-rule"


def default_rule_name(client: dict[str, Any]) -> str:
    cls = str(client.get("class") or client.get("initialClass") or "window")
    return sanitize_rule_name(cls)


def render_match_value(field: str, value: str) -> str:
    if field in BOOL_MATCH_FIELDS:
        return value.lower()
    if field == "workspace" and re.fullmatch(r"-?\d+", value):
        return value
    return lua_quote(value)


def render_rule(
    name: str,
    matchers: dict[str, str],
    effects: dict[str, str],
    use_helper: bool,
) -> str:
    match_lines = [f"  {key} = {render_match_value(key, value)}," for key, value in matchers.items()]

    if use_helper:
        lines = [
            f"rule({lua_quote(name)}, {{",
            *match_lines,
            "}, {",
        ]
        for key, value in effects.items():
            lines.append(f"  {key} = {value},")
        lines.append("})")
        return "\n".join(lines)

    lines = [
        "hl.window_rule({",
        f"  name = {lua_quote(name)},",
        "  match = {",
        *["  " + line for line in match_lines],
        "  },",
    ]
    for key, value in effects.items():
        lines.append(f"  {key} = {value},")
    lines.append("})")
    return "\n".join(lines)


def target_uses_helper(path: Path) -> bool:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return False
    return bool(re.search(r"\blocal\s+function\s+rule\s*\(", text))


def find_target(config_dir: Path, requested: str | None) -> Path:
    if requested:
        return Path(requested).expanduser()
    candidate = config_dir / "windows.lua"
    if candidate.exists():
        return candidate
    return config_dir / "hyprland.lua"


def copy_clipboard(text: str) -> bool:
    tool = shutil.which("wl-copy")
    if not tool:
        return False
    proc = subprocess.run([tool], input=text, text=True)
    return proc.returncode == 0


def open_editor(path: Path) -> bool:
    visual = os.environ.get("VISUAL", "").strip()
    editor = os.environ.get("EDITOR", "").strip()
    cmd_text = visual or editor
    if cmd_text:
        cmd = shlex.split(cmd_text) + [str(path)]
        source = "$VISUAL" if visual else "$EDITOR"
        print(f"Opening with {source}: {shlex.join(cmd)}")
        try:
            proc = subprocess.run(cmd)
        except OSError as exc:
            print(f"Could not start editor: {exc}")
            return False
        if proc.returncode != 0:
            print(f"Editor exited with status {proc.returncode}.")
            return False
        return True

    opener = shutil.which("xdg-open")
    if opener:
        print(f"Opening with xdg-open: {path}")
        try:
            proc = subprocess.run([opener, str(path)])
        except OSError as exc:
            print(f"Could not run xdg-open: {exc}")
            return False
        if proc.returncode != 0:
            print(f"xdg-open exited with status {proc.returncode}.")
            return False
        return True

    print(f"No $VISUAL/$EDITOR or xdg-open found. Open manually: {path}")
    return False


def append_rule(path: Path, name: str, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    prefix = ""
    if path.exists() and path.stat().st_size:
        existing = path.read_bytes()
        if not existing.endswith(b"\n"):
            prefix += "\n"
        prefix += "\n"
    block = (
        f"{prefix}-- BEGIN hypr-window-rule-builder: {name}\n"
        f"{text}\n"
        f"-- END hypr-window-rule-builder: {name}\n"
    )
    with path.open("a", encoding="utf-8") as fh:
        fh.write(block)


def validate_config() -> tuple[bool, str]:
    proc = subprocess.run(
        ["hyprctl", "reload"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    output = (proc.stdout + proc.stderr).strip()
    if proc.returncode != 0:
        return False, output
    err = subprocess.run(
        ["hyprctl", "configerrors"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    msg = (err.stdout + err.stderr).strip()
    if err.returncode == 0 and msg and msg.lower() not in {"ok", "no errors"}:
        return False, msg
    return True, output or "Reload requested."


def post_actions(target: Path, name: str, rule_text: str) -> str:
    while True:
        print()
        entries = [
            ("append_open", f"Append rule, then open {target} in editor"),
            ("append", f"Append rule without opening editor"),
            ("copy", "Copy rule to clipboard"),
            ("open", f"Open {target} without changing it"),
            ("edit", "Review/change this rule before writing"),
            ("rebuild", "Start this rule over"),
            ("done", "Cancel without changing the config"),
        ]
        action = fzf_select(entries, "Action>")[0]
        if action == "done":
            return "done"
        if action == "edit":
            return "edit"
        if action == "rebuild":
            return "rebuild"
        if action == "copy":
            if copy_clipboard(rule_text):
                print("Copied to clipboard.")
            else:
                print("wl-copy is not installed; rule was not copied.")
            continue
        if action == "open":
            open_editor(target)
            return "done"

        if action in {"append", "append_open"}:
            print()
            if not prompt_yes_no(f"Append this exact rule to {target}?", False):
                print("Not appended.")
                continue

            if target.exists() and rule_text in target.read_text(encoding="utf-8", errors="ignore"):
                print("That exact rule text is already present; not appending a duplicate.")
            else:
                existed_before = target.exists()
                previous = target.read_bytes() if existed_before else b""
                append_rule(target, name, rule_text)
                print(f"Appended to {target}")
                if prompt_yes_no("Reload Hyprland now?", True):
                    ok, message = validate_config()
                    print(message)
                    if not ok:
                        print("Hyprland reported a config problem.")
                        if prompt_yes_no("Restore the file to its pre-append state?", True):
                            if existed_before:
                                target.write_bytes(previous)
                            else:
                                target.unlink(missing_ok=True)
                            rollback = subprocess.run(
                                ["hyprctl", "reload"],
                                text=True,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
# __WRB_ASSEMBLY_GUARD_6_0__
# __WRB_ASSEMBLY_GUARD_6_1__
# __WRB_ASSEMBLY_GUARD_6_2__
# __WRB_ASSEMBLY_GUARD_6_3__
# __WRB_ASSEMBLY_GUARD_6_4__
# __WRB_ASSEMBLY_GUARD_6_5__
# __WRB_ASSEMBLY_GUARD_6_6__
                            )
                            print("Restored previous file and requested another reload.")
                            rollback_msg = (rollback.stdout + rollback.stderr).strip()
                            if rollback_msg:
                                print(rollback_msg)

            if action == "append_open":
                if not open_editor(target):
                    print(f"The rule was appended, but the editor did not open. File: {target}")
            return "done"


def parser_selftest() -> None:
    sample = r'''
local function rule(name, match, effects)
  effects.name = name
  effects.match = match
  hl.window_rule(effects)
end
rule("foo", { class = "^kitty$", float = false }, {
  float = true,
  size = { 800, 600 },
})
hl.window_rule({
  name = "bar",
  match = { title = "Hello.*" },
  opacity = "0.9 0.8",
})
'''
    rules = extract_rules_from_text(sample, Path("sample.lua"))
    assert len(rules) == 2, rules
    assert rules[0].name == "foo"
    assert rules[0].match["class"] == "^kitty$"
    assert rules[0].match["float"] is False
    assert rules[0].effects["float"] is True
    assert rules[1].name == "bar"
    assert rules[1].match["title"] == "Hello.*"
    print("Parser self-test passed.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Interactive Hyprland Lua window-rule builder")
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    parser.add_argument(
        "--config-dir",
        help="Hyprland config directory (default: $XDG_CONFIG_HOME/hypr or ~/.config/hypr)",
    )
    parser.add_argument("--target", help="Rule file to append/open (default: windows.lua if present)")
    parser.add_argument("--self-test", action="store_true", help="Run parser self-test and exit")
    args = parser.parse_args()

    if args.self_test:
        parser_selftest()
        return 0

    if not shutil.which("hyprctl"):
        eprint("hyprctl was not found in PATH.")
        return 2

    xdg = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    config_dir = Path(args.config_dir).expanduser() if args.config_dir else xdg / "hypr"
    target = find_target(config_dir, args.target)

    try:
        clients = run_json("clients")
        active = run_json("activewindow")
        monitors = run_json("monitors")
    except RuntimeError as exc:
        eprint(exc)
        return 2

    if not isinstance(clients, list) or not clients:
        eprint("Hyprland reports no open windows.")
        return 1
    if not isinstance(active, dict):
        active = {}
    if not isinstance(monitors, list):
        monitors = []

    client = choose_client(clients, active)
    if not client:
        return 0

    active_addr = str(active.get("address") or "")
    clear()
    print_client(client, monitors, active_addr)

    rules = scan_lua_rules(config_dir)
    matches = matching_rules(rules, client, active_addr)
    print_matching_rules(matches, config_dir)

    print()
    print(f"Rule target: {target}")
    print("New rules appended there will come after your existing rules and normally act as overrides.")

    default_name = default_rule_name(client)
    use_helper = target_uses_helper(target)

    while True:
        name = prompt_value("Rule name", default_name)
        matchers = build_match(client, active_addr)
        effects, effect_client, effect_monitors = build_effects(client, monitors)
        if not effects:
            print("A rule needs at least one effect. Nothing generated.")
            if prompt_yes_no("Start the rule over?", True):
                continue
            return 0

        while True:
            warn_about_static_title_match(matchers, effects, client)
            rule_text = render_rule(name, matchers, effects, use_helper)

            print()
            print("Generated rule")
            print("=" * min(80, terminal_width()))
            print(rule_text)
            print("=" * min(80, terminal_width()))
            print(f"Target: {target}")
            if use_helper:
                print("Using your local rule(name, match, effects) helper syntax.")
            else:
                print("Using native hl.window_rule({...}) syntax.")

            action = post_actions(target, name, rule_text)
            if action == "edit":
                edit_choice = fzf_select(
                    [
                        ("behavior", "Edit behavior / captured properties"),
                        ("match", "Edit how the window is identified"),
                        ("name", "Rename the rule"),
                        ("back", "Back to generated rule"),
                    ],
                    "Review>",
                    header="Nothing has been written yet.",
                )[0]
                if edit_choice == "behavior":
                    effects = edit_effects_draft(effect_client, effect_monitors, effects)
                    if not effects:
                        print("The rule now has no effects.")
                elif edit_choice == "match":
                    matchers = build_match(client, active_addr)
                elif edit_choice == "name":
                    name = prompt_value("Rule name", name)
                continue
            if action == "rebuild":
                print()
                print("Starting the rule over. Nothing has been written yet.")
                break
            return 0


def entrypoint() -> int:
    try:
        return main()
    except (KeyboardInterrupt, UserCancelled):
        print("\nCancelled. No further changes were made.")
        return 0


if __name__ == "__main__":
    raise SystemExit(entrypoint())
