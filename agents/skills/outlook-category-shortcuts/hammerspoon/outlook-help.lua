-- Popup with the Outlook category -> VIA key grid.
-- Trigger: the Megalodon big knob press on layer 2 must send ctrl+alt+cmd+H (QMK: LCAG(KC_H)).
-- Data comes from scripts/outlook-shortcuts.nu `list --json`, so it is always current.

local hotkey_mods, hotkey_key = { "ctrl", "alt", "cmd" }, "h"
local timeout_seconds = 15

local script = debug.getinfo(1, "S").source:sub(2):gsub("hammerspoon/[^/]+$", "scripts/outlook-shortcuts.nu")
local nu = "/opt/homebrew/bin/nu"

local view, closer, modal

local function close()
  if closer then closer:stop(); closer = nil end
  if modal then modal:exit(); modal = nil end
  if view then view:delete(); view = nil end
end

local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function html(slots)
  local cells = {}
  for _, s in ipairs(slots) do
    local cat = s.category and esc(s.category) or "&nbsp;"
    local cls = s.category and "" or " free"
    cells[#cells + 1] = string.format(
      '<div class="cell%s"><div class="k">%s</div><div class="c">%s</div></div>', cls, s.keys, cat)
  end
  return [[
<style>
  body { margin: 0; font: 14px -apple-system, sans-serif; background: #1e1e1e; color: #eee; }
  h1 { font-size: 15px; margin: 14px 16px 4px; font-weight: 600; }
  .sub { margin: 0 16px 10px; color: #999; font-size: 12px; }
  .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; padding: 0 16px 16px; }
  .cell { background: #2d2d2d; border-radius: 8px; padding: 10px; min-height: 44px; }
  .cell.free { opacity: .35; }
  .k { color: #8ab4f8; font-size: 12px; margin-bottom: 4px; }
  .c { font-weight: 600; word-break: break-word; }
</style>
<h1>Outlook categories &middot; VIA layer 2</h1>
<div class="sub">Esc or press again to close</div>
<div class="grid">]] .. table.concat(cells) .. "</div>"
end

local function show(slots)
  local screen = hs.screen.mainScreen():frame()
  local w, h = 720, 330
  local rect = hs.geometry.rect(screen.x + (screen.w - w) / 2, screen.y + (screen.h - h) / 2, w, h)
  view = hs.webview.new(rect)
    :windowStyle({ "borderless", "utility" })
    :level(hs.drawing.windowLevels.modalPanel)
    :allowTextEntry(false)
    :shadow(true)
    :html(html(slots))
    :show()
  modal = hs.hotkey.modal.new()
  modal:bind({}, "escape", close)
  modal:enter()
  closer = hs.timer.doAfter(timeout_seconds, close)
end

local function toggle()
  if view then return close() end
  hs.task.new(nu, function(code, out, err)
    if code ~= 0 then
      return hs.alert.show("outlook-shortcuts failed: " .. (err ~= "" and err or out), 5)
    end
    local ok, slots = pcall(hs.json.decode, out)
    if not ok or not slots then return hs.alert.show("bad JSON from outlook-shortcuts.nu", 5) end
    show(slots)
  end, { script, "list", "--json" }):start()
end

hs.hotkey.bind(hotkey_mods, hotkey_key, toggle)
