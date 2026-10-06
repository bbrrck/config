-- Reload kb16_01.layout.json onto the Megalodon by running via_load.py.
-- Trigger: the right wheel push sends ctrl+alt+cmd+R (QMK: LCAG(KC_R), layer 1 row 2 side key;
-- the other layers have KC_TRNS there, so it works on every layer).

local hotkey_mods = { "ctrl", "alt", "cmd" }
local hotkey_key = "r"

local script = debug.getinfo(1, "S").source:sub(2):gsub("hammerspoon/[^/]+$", "via_load.py")
local uv = "/opt/homebrew/bin/uv"

local task

local function reload()
  if task and task:isRunning() then return end
  hs.alert.show("Reloading VIA layout…")
  task = hs.task.new(uv, function(code, out, err)
    task = nil
    if code ~= 0 then
      return hs.alert.show("via_load failed: " .. (err ~= "" and err or out), 5)
    end
    local summary, last = nil, ""
    for line in out:gmatch("[^\n]+") do
      if line:match("change%(s%)") then summary = line end
      last = line
    end
    hs.alert.show(summary and (summary:gsub(":$", "") .. ". " .. last) or last, 3)
  end, { "run", "-q", script })
  task:start()
end

hs.hotkey.bind(hotkey_mods, hotkey_key, reload)
