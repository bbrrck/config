# Keyboard Mappings - VIA

For keyboard [Megalodon Triple Knob Macro Pad](https://www.keebmonkey.com/products/megalodon-triple-knob-macro-pad?variant=42941861658839)

⌘ = `KC_LGUI` = Command
⌃ = `KC_LCTL` = Control
⌥ = `KC_LALT` = Option
⇧ = `KC_LSFT` = Shift

## Layer 1: Rectangle (Rct) & Misc

Actions:

|      | col1                               | col2                     | col3                           | col4                |
| ---- | ---------------------------------- | ------------------------ | ------------------------------ | ------------------- |
| row1 | Rect - Previous Display            | Rect - Top Left          | Rect - Top Half                | Rect - Top Right    |
| row2 | Rect - Maximize                    | Rect - Left Half         | Rect - Center Half             | Rect - Right Half   |
| row3 | Rect - Next Display                | Rect - Bottom Left       | Rect - Bottom Half             | Rect - Bottom Right |
| row4 | Screenshot: Selection to Clipboard | Paste without formatting | Macro0 (LLM Prompt - Reformat) | Esc                 |

Keyboard Shortcuts - QMK codes:

|      | col1          | col2             | col3         | col4             |
| ---- | ------------- | ---------------- | ------------ | ---------------- |
| row1 | LCAG(KC_LEFT) | C(G(KC_LEFT))    | LAG(KC_UP)   | C(G(KC_RGHT))    |
| row2 | LAG(KC_F)     | LAG(KC_LEFT)     | LCAG(KC_UP)  | LAG(KC_RGHT)     |
| row3 | LCAG(KC_RGHT) | C(S(G(KC_LEFT))) | LAG(KC_DOWN) | C(S(G(KC_RGHT))) |
| row4 | C(S(G(KC_4))) | S(A(G(KC_V)))    | MACRO(0)     | KC_ESC           |

Keyboard Shortcuts - MacOS keys:

|      | col1 | col2 | col3 | col4 |
| ---- | ---- | ---- | ---- | ---- |
| row1 | ⌃⌥⌘← | ⌃⌘←  | ⌥⌘↑  | ⌃⌘→  |
| row2 | ⌥⌘F  | ⌥⌘←  | ⌃⌥⌘↑ | ⌥⌘→  |
| row3 | ⌃⌥⌘→ | ⌃⇧⌘← | ⌃⌘↓  | ⌃⇧⌘→ |
| row4 | ⌃⇧⌘4 | ⇧⌥⌘V | M0   | ESC  |
