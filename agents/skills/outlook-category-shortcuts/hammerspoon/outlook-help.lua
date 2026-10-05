-- Popup with the current VIA layer's keys and their meanings.
-- Trigger: the Megalodon big knob press sends ctrl+alt+cmd+<layer number> (QMK: LCAG(KC_1..4)),
-- so each layer opens its own popup. QMK cannot tell the Mac which layer is active.
-- Data comes from scripts/outlook-shortcuts.nu `layer <n> --json` (parses the VIA README;
-- layer 2 shows live Outlook categories), so it is always current.

local hotkey_mods = { "ctrl", "alt", "cmd" }
local layers = { 1, 2, 3, 4 } -- hotkey key = tostring(layer)
local timeout_seconds = 15

local script = debug.getinfo(1, "S").source:sub(2):gsub("hammerspoon/[^/]+$", "scripts/outlook-shortcuts.nu")
local nu = "/opt/homebrew/bin/nu"

local view, closer, modal, shown_layer

local function close()
  if closer then closer:stop(); closer = nil end
  if modal then modal:exit(); modal = nil end
  if view then view:delete(); view = nil end
  shown_layer = nil
end

local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function html(data)
  local cells = {}
  for _, row in ipairs(data.rows) do
    for _, c in ipairs(row) do
      local cls = "cell" .. (c.dim and " free" or "") .. (c.side and " side" or "")
      cells[#cells + 1] = string.format(
        '<div class="%s"><div class="k">%s</div><div class="c">%s</div></div>',
        cls, esc(c.keys), esc(c.action))
    end
  end
  return [[
<style>
  body { margin: 0; overflow: hidden; font: 14px -apple-system, sans-serif; background: #1e1e1e; color: #eee; }
  h1 { font-size: 15px; margin: 14px 16px 4px; font-weight: 600; }
  .sub { margin: 0 16px 10px; color: #999; font-size: 12px; }
  .grid { display: grid; grid-template-columns: repeat(4, 1fr) 0.9fr; gap: 8px; padding: 0 16px 16px; }
  .cell { background: #2d2d2d; border-radius: 8px; padding: 10px; min-height: 44px; }
  .cell.side { background: #26303d; }
  .cell.free { opacity: .35; }
  .k { color: #8ab4f8; font-size: 12px; margin-bottom: 4px; }
  .c { font-weight: 600; word-break: break-word; }
</style>
<h1>]] .. esc(data.title) .. [[</h1>
<div class="sub">Esc or press the knob again to close &middot; right column = side keys</div>
<div class="grid">]] .. table.concat(cells) .. "</div>"
end

local function show(data)
  local screen = hs.screen.mainScreen():frame()
  local w, h = 900, 375
  local rect = hs.geometry.rect(screen.x + (screen.w - w) / 2, screen.y + (screen.h - h) / 2, w, h)
  view = hs.webview.new(rect)
    :windowStyle({ "borderless", "utility" })
    :level(hs.drawing.windowLevels.modalPanel)
    :allowTextEntry(false)
    :shadow(true)
    :html(html(data))
    :show()
  shown_layer = data.layer
  modal = hs.hotkey.modal.new()
  modal:bind({}, "escape", close)
  modal:enter()
  closer = hs.timer.doAfter(timeout_seconds, close)
end

local function toggle(layer)
  if view then
    local same = (shown_layer == layer)
    close()
    if same then return end
  end
  hs.task.new(nu, function(code, out, err)
    if code ~= 0 then
      return hs.alert.show("outlook-shortcuts failed: " .. (err ~= "" and err or out), 5)
    end
    local ok, data = pcall(hs.json.decode, out)
    if not ok or not data then return hs.alert.show("bad JSON from outlook-shortcuts.nu", 5) end
    show(data)
  end, { script, "layer", tostring(layer), "--json" }):start()
end

for _, layer in ipairs(layers) do
  hs.hotkey.bind(hotkey_mods, tostring(layer), function() toggle(layer) end)
end
