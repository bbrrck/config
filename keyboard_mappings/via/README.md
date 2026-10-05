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

|      | col1                               | col2               | col3                     | col4                |
| ---- | ---------------------------------- | ------------------ | ------------------------ | ------------------- |
| row1 | Rect - Previous Display            | Rect - Top Left    | Rect - Top Half          | Rect - Top Right    |
| row2 | Rect - Maximize                    | Rect - Left Half   | Rect - Center Half       | Rect - Right Half   |
| row3 | Rect - Next Display                | Rect - Bottom Left | Rect - Bottom Half       | Rect - Bottom Right |
| row4 | Screenshot: Selection to Clipboard | Paste              | Paste without formatting | Esc                 |

Keyboard Shortcuts - QMK codes:

|      | col1          | col2             | col3          | col4             |
| ---- | ------------- | ---------------- | ------------- | ---------------- |
| row1 | LCAG(KC_LEFT) | C(G(KC_LEFT))    | LAG(KC_UP)    | C(G(KC_RGHT))    |
| row2 | LAG(KC_F)     | LAG(KC_LEFT)     | LCAG(KC_UP)   | LAG(KC_RGHT)     |
| row3 | LCAG(KC_RGHT) | C(S(G(KC_LEFT))) | LAG(KC_DOWN)  | C(S(G(KC_RGHT))) |
| row4 | C(S(G(KC_4))) | G(KC_V)          | S(A(G(KC_V))) | KC_ESC           |

Keyboard Shortcuts - MacOS keys:

|      | col1 | col2 | col3 | col4 |
| ---- | ---- | ---- | ---- | ---- |
| row1 | ⌃⌥⌘← | ⌃⌘←  | ⌥⌘↑  | ⌃⌘→  |
| row2 | ⌥⌘F  | ⌥⌘←  | ⌃⌥⌘↑ | ⌥⌘→  |
| row3 | ⌃⌥⌘→ | ⌃⇧⌘← | ⌃⌘↓  | ⌃⇧⌘→ |
| row4 | ⌃⇧⌘4 | ⌘V   | ⇧⌥⌘V | ESC  |

## Layer 2: Outlook Keyboard Shortcuts (assign categories)

Actions:

|      | col1                      | col2                      | col3                      | col4                      |
| ---- | ------------------------- | ------------------------- | ------------------------- | ------------------------- |
| row1 | Assign Category #1 (F1)   | Assign Category #2 (F2)   | Assign Category #3 (F3)   | Assign Category #4 (F4)   |
| row2 | Assign Category #5 (F5)   | Assign Category #6 (F6)   | Assign Category #7 (F7)   | Assign Category #8 (F8)   |
| row3 | Assign Category #9 (F9)   | Assign Category #10 (F10) | Assign Category #11 (F11) | Assign Category #12 (F12) |
| row4 | Assign Category #13 (F13) | Assign Category #14 (F14) | Assign Category #15 (F15) | Assign Category #16 (F16) |

Keyboard Shortcuts - QMK codes:

|      | col1         | col2         | col3         | col4         |
| ---- | ------------ | ------------ | ------------ | ------------ |
| row1 | C(G(KC_F1))  | C(G(KC_F2))  | C(G(KC_F3))  | C(G(KC_F4))  |
| row2 | C(G(KC_F5))  | C(G(KC_F6))  | C(G(KC_F7))  | C(G(KC_F8))  |
| row3 | C(G(KC_F9))  | C(G(KC_F10)) | C(G(KC_F11)) | C(G(KC_F12)) |
| row4 | C(G(KC_F13)) | C(G(KC_F14)) | C(G(KC_F15)) | C(G(KC_F16)) |

Keyboard Shortcuts - MacOS keys:

|      | col1  | col2  | col3  | col4  |
| ---- | ----- | ----- | ----- | ----- |
| row1 | ⌃⌘F1  | ⌃⌘F2  | ⌃⌘F3  | ⌃⌘F4  |
| row2 | ⌃⌘F5  | ⌃⌘F6  | ⌃⌘F7  | ⌃⌘F8  |
| row3 | ⌃⌘F9  | ⌃⌘F10 | ⌃⌘F11 | ⌃⌘F12 |
| row4 | ⌃⌘F13 | ⌃⌘F14 | ⌃⌘F15 | ⌃⌘F16 |

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

Pressing the big round knob on **layer 2** opens a popup showing which Outlook category is
on which key. The popup is always current because it reads `list --json` on every press.

How it fits together:

1. **VIA:** the layer-2 knob press sends `LCAG(KC_H)` = `⌃⌥⌘H`. Layer 1 keeps `KC_MUTE`.
2. **Hammerspoon** ([hammerspoon.org](https://www.hammerspoon.org/), free and open source)
   listens for `⌃⌥⌘H`, runs the nushell script, and draws the grid in a borderless web view.
3. **Config:** `agents/skills/outlook-category-shortcuts/hammerspoon/outlook-help.lua`.
   Hotkey, popup timeout and the `nu` path are variables at the top of the file.

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

Usage: press the knob on layer 2. The popup closes on `Esc`, on pressing the knob again,
or after 15 seconds. Pressing `⌃⌥⌘H` on a normal keyboard also works, which helps with debugging.

Troubleshooting:

- Nothing appears: check the Hammerspoon Console for Lua errors and confirm Accessibility
  permission is granted.
- Alert "outlook-shortcuts failed": the `nu` call errored; the alert shows the message.
  The script expects nushell at `/opt/homebrew/bin/nu`.
- Hotkey does nothing: another app may own `⌃⌥⌘H`, or the knob is not sending `LCAG(KC_H)`.

## Layer 3: Quarto / reveal.js Presentations

Standard reveal.js/Quarto presentation controls. reveal.js treats
Left/Up and Right/Down as aliases for prev/next (not separate overview
navigation), and Esc/O as aliases for toggling overview, so each pair is
mapped to a single key here rather than duplicated.

The 5th ("side") key on row 3 carries Search (`⌃⇧F`), since it doesn't fit
the 4x4 action grid. Row 4 col4 (`KC_F20`) is an unrelated legacy binding
kept as-is. The 5th ("side") key on row 4 carries Toggle Full Screen in
Browser (`⌘⇧F`), since it doesn't fit the 4x4 action grid either.

Actions:

|      | col1                | col2               | col3                | col4                |
| ---- | ------------------- | ------------------ | ------------------- | ------------------- |
| row1 | Previous Slide      | Next Slide         | Prev (no fragments) | Next (no fragments) |
| row2 | Jump to First Slide | Jump to Last Slide | Slide Overview      | Jump to Slide (G)   |
| row3 | Toggle Fullscreen   | Speaker Notes      | Pause (Black)       | Scroll View Mode    |
| row4 | Toggle Menu         | PDF Export Mode    | Help                | (legacy: KC_F20)    |

Keyboard Shortcuts - QMK codes:

|      | col1       | col2       | col3       | col4       |
| ---- | ---------- | ---------- | ---------- | ---------- |
| row1 | KC_LEFT    | KC_RGHT    | A(KC_LEFT) | A(KC_RGHT) |
| row2 | S(KC_LEFT) | S(KC_RGHT) | KC_O       | KC_G       |
| row3 | KC_F       | KC_S       | KC_B       | KC_R       |
| row4 | KC_M       | KC_E       | S(KC_SLSH) | KC_F20     |

Row 3 side key (Search): `C(S(KC_F))`

Row 4 side key (Toggle Full Screen in Browser): `G(S(KC_F))`

Keyboard Shortcuts - MacOS keys:

|      | col1 | col2 | col3 | col4 |
| ---- | ---- | ---- | ---- | ---- |
| row1 | ←    | →    | ⌥←   | ⌥→   |
| row2 | ⇧←   | ⇧→   | O    | G    |
| row3 | F    | S    | B    | R    |
| row4 | M    | E    | ⇧/   | -    |

Row 3 side key (Search): ⌃⇧F

Row 4 side key (Toggle Full Screen in Browser): ⌘⇧F
