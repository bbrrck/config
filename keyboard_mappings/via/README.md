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
```

After making changes, you might need to restart Outlook for the changes to take effect:

```bash
killall 'Microsoft Outlook'
```
