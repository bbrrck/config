---
name: outlook-category-shortcuts
description: Use when asked to show, list, add, change, or remove Microsoft Outlook (macOS) category keyboard shortcuts, or to see which key on the VIA Megalodon macro pad (layer 2) triggers which Outlook category.
---

# Outlook Category Shortcuts

Outlook category shortcuts are `⌃⌘F1`..`⌃⌘F16`, stored in `defaults` (`com.microsoft.Outlook` / `NSUserKeyEquivalents`). The Megalodon pad's layer 2 sends those combos from a 4x4 grid, row-major: `Fn` is at row `(n-1)//4+1`, col `(n-1)%4+1`. Full keyboard docs: `keyboard_mappings/via/README.md` in the config repo.

All actions go through one nushell script (macOS only):

```bash
nu <skill-dir>/scripts/outlook-shortcuts.nu <subcommand>
```

| Goal | Command |
|---|---|
| Grid view (default) | `list` |
| Flat table: category, keys, VIA layer/row/col | `list --list` |
| Bind category to slot 1-16 | `set 'BTS/Edu' 2` |
| Replace category already on that slot | `set 'P/New' 2 --force` |
| Unbind category | `remove 'BTS/Edu'` |
| Machine-readable, all 16 slots | `list --json` |

## Help popup (Hammerspoon)

`hammerspoon/outlook-help.lua` shows the grid in a popup on `⌃⌥⌘H`. Load it from `~/.hammerspoon/init.lua`:

```lua
dofile(os.getenv("HOME") .. "/.claude/skills/outlook-category-shortcuts/hammerspoon/outlook-help.lua")
```

The pad's layer-2 knob press must send `LCAG(KC_H)`; set that in VIA (Key tester / Encoders). Hammerspoon needs Accessibility permission.

## Rules

- Show the grid for read requests unless the user asks for a list.
- `set` refuses a slot used by another category; ask the user before using `--force`.
- Category name must match the Outlook category exactly (case, `/`).
- Non-F-key bindings are preserved and reported, never changed.
- Each write saves a timestamped backup to `~/outlook-shortcuts-backup-<stamp>.plist`.
- After a write, tell the user to restart Outlook: `killall 'Microsoft Outlook'`.
- Slot `F16` is conventionally "Clear All". Run `list` to see which slots are free.

## Common mistakes

- Using `defaults write -dict-add` by hand: value must be `@^` + the Unicode char `U+F704 + (n-1)`, not the text `\UF705`. Use the script.
- Expecting the pad to change: the pad is fixed in VIA; only the Outlook side is configurable here. Remapping pad keys needs the VIA app.
