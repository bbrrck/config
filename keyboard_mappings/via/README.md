# Keyboard Mappings - VIA

For keyboard [Megalodon Triple Knob Macro Pad](https://www.keebmonkey.com/products/megalodon-triple-knob-macro-pad?variant=42941861658839)

⌘ = `KC_LGUI` = Command
⌃ = `KC_LCTL` = Control
⌥ = `KC_LALT` = Option
⇧ = `KC_LSFT` = Shift

QMK reference for modifier keys:

- `A(...)` = Alt/Option
- `C(...)` = Control
- `G(...)` = GUI/Command
- `S(...)` = Shift
- `LAG(...)` = Left Alt + Left GUI
- `LCAG(...)` = Left Control + Left Alt + Left GUI

For full reference, see [docs.qmk.fm/keycodes](https://docs.qmk.fm/keycodes)

## Layer 1: Rectangle (Rct) & Misc

Actions:

|      | col1                               | col2               | col3                     | col4                | side                |
| ---- | ---------------------------------- | ------------------ | ------------------------ | ------------------- | ------------------- |
| row1 | Rect - Previous Display            | Rect - Top Left    | Rect - Top Half          | Rect - Top Right    | Go to Layer 4 (RGB) |
| row2 | Rect - Maximize                    | Rect - Left Half   | Rect - Center Half       | Rect - Right Half   | Go to Layer 2       |
| row3 | Rect - Next Display                | Rect - Bottom Left | Rect - Bottom Half       | Rect - Bottom Right | Help popup          |
| row4 | Screenshot: Selection to Clipboard | Paste              | Paste without formatting | Esc                 | (none)              |

Keyboard Shortcuts - QMK codes:

|      | col1          | col2             | col3          | col4             | side       |
| ---- | ------------- | ---------------- | ------------- | ---------------- | ---------- |
| row1 | LCAG(KC_LEFT) | C(G(KC_LEFT))    | LAG(KC_UP)    | C(G(KC_RGHT))    | TO(3)      |
| row2 | LAG(KC_F)     | LAG(KC_LEFT)     | LCAG(KC_UP)   | LAG(KC_RGHT)     | TO(1)      |
| row3 | LCAG(KC_RGHT) | C(S(G(KC_LEFT))) | LAG(KC_DOWN)  | C(S(G(KC_RGHT))) | LCAG(KC_1) |
| row4 | C(S(G(KC_4))) | G(KC_V)          | S(A(G(KC_V))) | KC_ESC           | KC_NO      |

Keyboard Shortcuts - MacOS keys:

|      | col1 | col2 | col3 | col4 | side    |
| ---- | ---- | ---- | ---- | ---- | ------- |
| row1 | ⌃⌥⌘← | ⌃⌘←  | ⌥⌘↑  | ⌃⌘→  | layer 4 |
| row2 | ⌥⌘F  | ⌥⌘←  | ⌃⌥⌘↑ | ⌥⌘→  | layer 2 |
| row3 | ⌃⌥⌘→ | ⌃⇧⌘← | ⌃⌘↓  | ⌃⇧⌘→ | ⌃⌥⌘1    |
| row4 | ⌃⇧⌘4 | ⌘V   | ⇧⌥⌘V | ESC  | -       |

## Layer 2: Outlook Keyboard Shortcuts (assign categories)

Actions:

|      | col1                      | col2                      | col3                      | col4                      | side          |
| ---- | ------------------------- | ------------------------- | ------------------------- | ------------------------- | ------------- |
| row1 | Assign Category #1 (F1)   | Assign Category #2 (F2)   | Assign Category #3 (F3)   | Assign Category #4 (F4)   | Go to Layer 1 |
| row2 | Assign Category #5 (F5)   | Assign Category #6 (F6)   | Assign Category #7 (F7)   | Assign Category #8 (F8)   | Go to Layer 3 |
| row3 | Assign Category #9 (F9)   | Assign Category #10 (F10) | Assign Category #11 (F11) | Assign Category #12 (F12) | Help popup    |
| row4 | Assign Category #13 (F13) | Assign Category #14 (F14) | Assign Category #15 (F15) | Assign Category #16 (F16) | (none)        |

Keyboard Shortcuts - QMK codes:

|      | col1         | col2         | col3         | col4         | side       |
| ---- | ------------ | ------------ | ------------ | ------------ | ---------- |
| row1 | C(G(KC_F1))  | C(G(KC_F2))  | C(G(KC_F3))  | C(G(KC_F4))  | TO(0)      |
| row2 | C(G(KC_F5))  | C(G(KC_F6))  | C(G(KC_F7))  | C(G(KC_F8))  | TO(2)      |
| row3 | C(G(KC_F9))  | C(G(KC_F10)) | C(G(KC_F11)) | C(G(KC_F12)) | LCAG(KC_2) |
| row4 | C(G(KC_F13)) | C(G(KC_F14)) | C(G(KC_F15)) | C(G(KC_F16)) | KC_NO      |

Keyboard Shortcuts - MacOS keys:

|      | col1  | col2  | col3  | col4  | side    |
| ---- | ----- | ----- | ----- | ----- | ------- |
| row1 | ⌃⌘F1  | ⌃⌘F2  | ⌃⌘F3  | ⌃⌘F4  | layer 1 |
| row2 | ⌃⌘F5  | ⌃⌘F6  | ⌃⌘F7  | ⌃⌘F8  | layer 3 |
| row3 | ⌃⌘F9  | ⌃⌘F10 | ⌃⌘F11 | ⌃⌘F12 | ⌃⌥⌘2    |
| row4 | ⌃⌘F13 | ⌃⌘F14 | ⌃⌘F15 | ⌃⌘F16 | -       |

Use the following command to assign keyboard shortcuts to Outlook categories:

```bash
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add 'CATEGORY_NAME' '^@\UF7XX'
```

Replace `CATEGORY_NAME` with the name of the category (e.g., 'BTS/General') and `XX` with the corresponding function key number:

- F1 = `\UF704`
- F2 = `\UF705`
- F3 = `\UF706`
- F4 = `\UF707`
- F5 = `\UF708`
- F6 = `\UF709`
- F7 = `\UF70A`
- F8 = `\UF70B`
- F9 = `\UF70C`
- F10 = `\UF70D`
- F11 = `\UF70E`
- F12 = `\UF70F`
- F13 = `\UF710`
- F14 = `\UF711`
- F15 = `\UF712`
- F16 = `\UF713`

Example:

```bash
# Add keyboard shortcut: assign outlok category 'BTS/Edu' when pressing ⌃⌘F2
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add 'BTS/Edu' '^@\UF705'

# Add keyboard shortcut: clear all categories when pressing ⌃⌘F14
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict-add 'Clear All' '^@\UF711'

# List all configured keyboard shortcuts
defaults read com.microsoft.Outlook NSUserKeyEquivalents 
```

After making changes, you might need to restart Outlook for the changes to take effect:

```bash
killall 'Microsoft Outlook'
```

### Managing the shortcuts: `outlook-category-shortcuts` skill

Instead of running `defaults` by hand, use the agent skill
`agents/skills/outlook-category-shortcuts/` (this repo). It wraps a nushell
script, `scripts/outlook-shortcuts.nu`, and can be invoked in Claude Code as
`/outlook-category-shortcuts <request>` (e.g. `show`, `set F6 to P/SpecSubOptim`).

Setup: the skill directory is symlinked into both skill folders.

```bash
ln -sfn ~/Projects/config/agents/skills/outlook-category-shortcuts ~/.agents/skills/outlook-category-shortcuts
ln -sfn ~/Projects/config/agents/skills/outlook-category-shortcuts ~/.claude/skills/outlook-category-shortcuts
```

Script commands (requires macOS and [nushell](https://www.nushell.sh/)):

| Goal                                   | Command                               |
| -------------------------------------- | ------------------------------------- |
| Grid view of layer 2 (default)         | `nu scripts/outlook-shortcuts.nu list`           |
| Flat table: category, keys, layer/row/col | `... list --list`                  |
| JSON for all 16 slots (used by popup)  | `... list --json`                     |
| Bind a category to slot 1-16 (`Fn`)    | `... set 'BTS/Edu' 2`                 |
| Replace the category already on a slot | `... set 'P/New' 2 --force`           |
| Unbind a category                      | `... remove 'BTS/Edu'`                |

Behavior:

- Slot `n` maps to the layer-2 key at row `(n-1)//4+1`, col `(n-1)%4+1` and sends `⌃⌘Fn`.
- The value stored in `NSUserKeyEquivalents` is `@^` + the Unicode character `U+F704 + (n-1)`
  (the macOS function-key private-use range), not the literal text `\UF705`.
  The script builds this for you.
- `set` refuses a slot used by another category unless `--force` is given.
- Bindings that are not in the `⌃⌘F1..F16` scheme are preserved and reported, never changed.
- Every write saves a backup to `~/outlook-shortcuts-backup-<timestamp>.plist` and replaces
  the whole `NSUserKeyEquivalents` dict in one `defaults write`.
- Restart Outlook afterwards (`killall 'Microsoft Outlook'`).
- The script only changes the Outlook side. The pad itself (layer 2 sending `⌃⌘F1..F16`) is
  configured in VIA.

### Help popup on the big knob (Hammerspoon)

Pressing the big round knob (the row 3 side key) opens a popup showing the current layer's
keys with their meanings. Every layer has its own combo, so the popup knows which layer it is:

| Layer | Knob sends   | Popup shows                                           |
| ----- | ------------ | ----------------------------------------------------- |
| 1     | `LCAG(KC_1)` | Rectangle & misc                                      |
| 2     | `LCAG(KC_2)` | Outlook categories (live, read from Outlook settings) |
| 3     | `LCAG(KC_3)` | Quarto / reveal.js                                    |
| 4     | `LCAG(KC_4)` | RGB lighting                                          |

How it fits together:

1. **VIA:** the knob key on each layer sends `⌃⌥⌘` + the layer number (table above).
   `kb16_01.layout.json` in this folder has these keycodes; load it in VIA to apply.
   The old knob bindings (layer 1 `C(KC_R)`, layer 3 Search `C(S(KC_F))`) are gone.
2. **Hammerspoon** ([hammerspoon.org](https://www.hammerspoon.org/), free and open source)
   listens for `⌃⌥⌘1..4`, runs `outlook-shortcuts.nu layer <n> --json`, and draws the
   grid (4x4 keys + side column) in a borderless web view. QMK cannot report the active
   layer to the Mac, which is why each layer sends its own combo.
3. **Content:** `scripts/outlook-shortcuts.nu` parses the `## Layer N:` sections of this
   README (the `Actions:` and `Keyboard Shortcuts - MacOS keys:` tables, including the
   `side` column). **Keep those two tables in this format when editing**: the popup
   is generated from them. Layer 2 replaces the "Assign Category" text with the live
   category names.
4. **Config:** `agents/skills/outlook-category-shortcuts/hammerspoon/outlook-help.lua`.
   Hotkeys, popup timeout and the `nu` path are variables at the top of the file.

Setup:

```bash
brew install --cask hammerspoon
open -a Hammerspoon   # grant Accessibility permission in System Settings when asked
```

Create `~/.hammerspoon/init.lua`:

```lua
dofile(os.getenv("HOME") .. "/.claude/skills/outlook-category-shortcuts/hammerspoon/outlook-help.lua")
```

Then click the Hammerspoon menu bar icon and choose Reload Config.

Usage: press the knob on any layer. The popup closes on `Esc`, on pressing the knob again,
or after 15 seconds. `⌃⌥⌘1..4` on a normal keyboard also works, which helps with debugging.
Preview a layer in the terminal: `nu scripts/outlook-shortcuts.nu layer 3`.

Troubleshooting:

- Nothing appears: check the Hammerspoon Console for Lua errors and confirm Accessibility
  permission is granted.
- Alert "outlook-shortcuts failed": the `nu` call errored; the alert shows the message.
  The script expects nushell at `/opt/homebrew/bin/nu`. If it says no `## Layer N:` section,
  set `VIA_README` to this file's path.
- Hotkey does nothing: another app may own `⌃⌥⌘<n>`, or the knob is not sending `LCAG(KC_<n>)`.

## Layer 3: Quarto / reveal.js Presentations

Standard reveal.js/Quarto presentation controls. reveal.js treats
Left/Up and Right/Down as aliases for prev/next (not separate overview
navigation), and Esc/O as aliases for toggling overview, so each pair is
mapped to a single key here rather than duplicated.

The 5th ("side") column holds layer switches, the help-popup knob (row 3) and
Toggle Full Screen in Browser (`⌘⇧F`, row 4). Row 4 col4 (`KC_F20`) is an unrelated
legacy binding kept as-is. Search (`⌃⇧F`, `C(S(KC_F))`) used to live on the row 3
side key; it was replaced by the help popup and is no longer mapped.

Actions:

|      | col1                | col2               | col3                | col4                | side                          |
| ---- | ------------------- | ------------------ | ------------------- | ------------------- | ----------------------------- |
| row1 | Previous Slide      | Next Slide         | Prev (no fragments) | Next (no fragments) | Go to Layer 2                 |
| row2 | Jump to First Slide | Jump to Last Slide | Slide Overview      | Jump to Slide (G)   | Go to Layer 4 (RGB)           |
| row3 | Toggle Fullscreen   | Speaker Notes      | Pause (Black)       | Scroll View Mode    | Help popup                    |
| row4 | Toggle Menu         | PDF Export Mode    | Help                | (legacy: KC_F20)    | Toggle Full Screen in Browser |

Keyboard Shortcuts - QMK codes:

|      | col1       | col2       | col3       | col4       | side       |
| ---- | ---------- | ---------- | ---------- | ---------- | ---------- |
| row1 | KC_LEFT    | KC_RGHT    | A(KC_LEFT) | A(KC_RGHT) | TO(1)      |
| row2 | S(KC_LEFT) | S(KC_RGHT) | KC_O       | KC_G       | TO(3)      |
| row3 | KC_F       | KC_S       | KC_B       | KC_R       | LCAG(KC_3) |
| row4 | KC_M       | KC_E       | S(KC_SLSH) | KC_F20     | G(S(KC_F)) |

Keyboard Shortcuts - MacOS keys:

|      | col1 | col2 | col3 | col4 | side    |
| ---- | ---- | ---- | ---- | ---- | ------- |
| row1 | ←    | →    | ⌥←   | ⌥→   | layer 2 |
| row2 | ⇧←   | ⇧→   | O    | G    | layer 4 |
| row3 | F    | S    | B    | R    | ⌃⌥⌘3    |
| row4 | M    | E    | ⇧/   | -    | ⌘⇧F     |

## Layer 4: RGB Lighting

RGB underglow controls. `KC_TRNS` keys ("-") fall through to the layer below.

Actions:

|      | col1                | col2                | col3                | col4                | side                |
| ---- | ------------------- | ------------------- | ------------------- | ------------------- | ------------------- |
| row1 | RGB Speed +         | RGB Speed -         | -                   | -                   | Go to Layer 3       |
| row2 | RGB Saturation +    | RGB Saturation -    | -                   | -                   | Go to Layer 1       |
| row3 | RGB Toggle          | RGB Next Mode       | RGB Hue +           | -                   | Help popup          |
| row4 | -                   | RGB Brightness +    | RGB Hue -           | RGB Brightness -    | (none)              |

Keyboard Shortcuts - QMK codes:

|      | col1     | col2     | col3    | col4    | side       |
| ---- | -------- | -------- | ------- | ------- | ---------- |
| row1 | RGB_SPI  | RGB_SPD  | KC_TRNS | KC_TRNS | TO(2)      |
| row2 | RGB_SAI  | RGB_SAD  | KC_TRNS | KC_TRNS | TO(0)      |
| row3 | RGB_TOG  | RGB_MOD  | RGB_HUI | KC_TRNS | LCAG(KC_4) |
| row4 | KC_TRNS  | RGB_VAI  | RGB_HUD | RGB_VAD | KC_NO      |

Keyboard Shortcuts - MacOS keys:

|      | col1    | col2    | col3    | col4    | side    |
| ---- | ------- | ------- | ------- | ------- | ------- |
| row1 | SPD +   | SPD -   | -       | -       | layer 3 |
| row2 | SAT +   | SAT -   | -       | -       | layer 1 |
| row3 | RGB     | MODE    | HUE +   | -       | ⌃⌥⌘4    |
| row4 | -       | VAL +   | HUE -   | VAL -   | -       |
